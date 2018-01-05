<#
    .Synopsis
      Will install Pandoc on a Windows PC. It does this by downloading the latest .msi release
    .DESCRIPTION
      Tested on Windows 7 Enterprise. 

    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info"
,[Parameter(position=1)][string] $specifiedTag = $null
,[switch] $winEventLog
,[switch] $cleanupLocalFiles)

Import-Module FC_Log, FC_Git -Force

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog
Set-LogFormattingOptions -PrefixCallingFunction 1 -AutoTabCallsFromFunctions 1

try{
    $releasePath = Get-GitHubRelease -repo "jgm/pandoc" -fileFormat "pandoc-0-windows.msi" -tag $specifiedTag
    Write-Log "The pandoc installer was downloaded into $releasePath"
    Write-Log "Running the installer"
    $output = Start-MyProcess -EXEPath "msiexec.exe" -options "/I $releasePath /quiet /norestart"

    if ($($output.stderr) -ne ""){
            Write-Log "$($output.stderr)" Warning
            Write-Log "There was an error in the stderr stream. See above warning for the error text" Error -ErrorAction Stop
        }
    elseif ($($output.stdout) -ne ""){
            Write-Log "$($output.stdout)" Debug
            if ($($output.stdout) -contains "error"){
    
                Write-Log "There was a Error detected in the stdout from " Error -ErrorAction Stop
            }
        }
    elseif ($($output.ExitCode -ne 0)){
        Write-Log "The pandoc installer returned $($output.ExitCode)." Error -ErrorAction Stop
    }
    Write-Log "The pandoc installer appears to have completed succesfully"
}
catch{
    $ex = $_.Exception
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    $errorMessage = $ex.Message 
    Write-Log "Error at line $errorLine. Error message: $errorMessage" Warning
}


Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
