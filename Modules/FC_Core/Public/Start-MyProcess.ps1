function Start-MyProcess {
  <#
.Synopsis
Wraps up a call to execute a program using System.Diagnostics.Process. This allows us to redirect the stdout and stderr streams for better error handling. Specifcially this is used for quite a few MS utilities in our TFS build/deploy, as the utilities will usually throw warnings instead of terminating errors and we need to parse stdout to determine if there was an actuall error.
.DESCRIPTION
Wrapper for calling processes
.EXAMPLE
This example sets up a executable path, and options, then passes them to the function while captureing the returning stdout and stderr streams.

Assume that $dacDinDir, $DestFile, $ConnectionString are all set to sueful values.

$EXEPath = "$dacBinDir\SqlPackage.exe"
$options = "/Action:Extract /OverwriteFiles:True /tf:$DestFile /scs:$ConnectionString"

$return = Start-MyProcess -EXEPath  $EXEPath -options $options

if ($logLevel -eq "Debug"){
	#Only show the stdout stream if we are in debugging logLevel
	$return.stddout
}
if ($return.stderr -ne $null){
	Write-Log "$($return.stderr)" Warning
	Write-Log "There was an error of some type. See warning above for more info" Error
}
.OUTPUTS
A object with 3 properties, stdout, stderr, and ExitCode. stdout and stderr are text streams that conatian output from the process. Generally if (stderr -eq $null) then there was some sort of error. You can also parse stdout to find errors, or check the ExitCode for non-success
#>
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Position = 0)] [string]$EXEPath
    , [Parameter(Position = 1)][string]$options
    , [ValidateSet("Debug", "Info", "Warning", "Error", "Disable")] [string]$logLevel = "Warning"
    , [switch]$async
    , [int]$sleepTimer = 5
    , [string]$workingDir
    , $stderrDelegate
    , $stdoutDelegate
  )

  Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  $currentLogLevel = Get-LogLevel
  if ([string]::IsNullOrEmpty($logLevel)) {
    $logLevel = "Warning"
  }
  Set-LogLevel $logLevel
  $EXE = $EXEPath.Substring($EXEPath.LastIndexOf("\") + 1, $EXEPath.Length - $EXEPath.LastIndexOf("\") - 1)
  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  if ($IsWindows) {
    $pinfo.FileName = "`"$EXEPath`""
  }
  else {
    $pinfo.FileName = "$EXEPath"
  }
  $pinfo.Arguments = "$options"
  $pinfo.UseShellExecute = $false
  $pinfo.CreateNoWindow = $true
  if ([string]::IsNullOrEmpty($workingDir)) {
    $pinfo.WorkingDirectory = Get-Location
  }
  else {
    $pinfo.WorkingDirectory = $workingDir
  }
  $pinfo.RedirectStandardOutput = $true
  $pinfo.RedirectStandardError = $true

  # Create a process object using the startup info
  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $pinfo

  if ($async) {
    # Register Object Events for stdin\stdout streams
    if (![string]::IsNullOrEmpty($stdoutDelegate)) {
      Write-Output (Register-ObjectEvent -Action $stdoutDelegate -InputObject $Process -EventName OutputDataReceived -SourceIdentifier "$(Split-Path $EXEPath -Leaf)|stdout|$(New-Guid)|")
    }
    if (![string]::IsNullOrEmpty($stdoutDelegate)) {
      Write-Output (Register-ObjectEvent -Action $stderrDelegate -InputObject $Process -EventName ErrorDataReceived -SourceIdentifier "$(Split-Path $EXEPath -Leaf)|stderr|$(New-Guid)|")
    }

  }
  Write-Log "Executing the following command" Debug
  Write-Log " $($pinfo.Arguments)" Debug
  try {
    $process.Start() | Out-Null
  }
  catch {
    Write-Log "****Process errors****" Warning
    Write-Log "$($_.Exception.ToString())" Warning
    Write-Log "Error calling $EXE. See previous warning(s) for error text. Try running the script with a lower logLevel variable to collect more troubleshooting information. Aborting script" Error -ErrorAction Stop

  }

  if (!$async) {
    if (!$process.HasExited) {
      # Wait a while for the process to exitn
      Write-Log "$EXE is not done, let's wait $sleepTimer more seconds"
      Start-Sleep -Seconds $sleepTimer
    }
    Write-Log "$EXE has completed."
    # get output from stdout and stderr
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()

    $stdOutput = New-Object -TypeName PSObject
    $stdOutput | Add-Member -MemberType NoteProperty -Name stderr -Value $stderr
    $stdOutput | Add-Member -MemberType NoteProperty -Name stdout -Value $stdout
    $stdOutput | Add-Member -MemberType NoteProperty -Name exitCode -Value $process.ExitCode

    $returnVal = $stdOutput
  }
  else {
    $Process.BeginOutputReadLine()
    $Process.BeginErrorReadLine()
    $returnVal = $process
  }

  Set-LogLevel $currentLogLevel
  return $returnVal
} Export-ModuleMember -Function Start-MyProcess
