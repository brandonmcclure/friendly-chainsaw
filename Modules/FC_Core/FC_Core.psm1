function Set-ScriptSignature {
    <#
    .SYNOPSIS
    Signs the current file in the ISE with the user's code-signing certificate. You
    must have a valid code-signing certificate in your personal certificate store
    for this to work. Prompts for save location if the file has not yet been saved.
    .NOTES 
    Author: Matt McNabb
    Date: 8/22/2014 
    DISCLAIMER: This script is provided 'AS IS'. It has been tested for personal use, please  
    test in a lab environment before using in a production environment.
    #> 
    if ($host.name -eq 'Windows PowerShell ISE Host') {

    function Get-FileSavePath {
        $SaveDialog = New-Object -TypeName System.Windows.Forms.SaveFileDialog
        $SaveDialog.Filter = 'Powershell Files(*.ps1;*.psm1;*.psd1;*.ps1xml;*.pssc*;*.cdxml)|*.ps1;*.psm1;*.psd1;*.ps1xml;*.pssc*;*.cdxml|All files (*.*)|*.*'
        $SaveDialog.FilterIndex = 1
        $SaveDialog.RestoreDirectory = $true
        $SaveDialog.ShowDialog()
        $SaveDialog.FileName
    }
    
        $File = $psise.CurrentFile
        $Path = $File.FullPath
        $Certificate = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
        if ($Certificate)
        {
            if ($File.IsUntitled)
            {
                $Path = Get-FileSavePath
                $File.SaveAs($Path,[text.encoding]::utf8)
            }
            if (-not($File.IsSaved)) {$File.Save([text.encoding]::utf8)}
            Add-Content -Path $Path -Value ''
            Set-AuthenticodeSignature -FilePath $Path -Certificate $Certificate | Out-Null
            $psise.CurrentPowerShellTab.Files.Remove($File) | Out-Null
            $psise.CurrentPowerShellTab.Files.Add($Path) | Out-Null
        }
        else {throw 'A valid code-signing certificate could not be found!'} 
    }
}export-modulemember -function Set-ScriptSignature

function Start-MyProcess {
<#
    .Synopsis
      Wraps up a call to execute a program using System.Diagnostics.Process. This allows us to redirect the stdout and stderr streams for better error handling. Specifcially this is used for quite a few MS utilities in our TFS build/deploy, as the utilities will usually throw warnings instead of terminating errors and we need to parse stdout to determine if there was an actuall error. 
    .DESCRIPTION
       
    .EXAMPLE
        This example sets up a executable path, and options, then passes them to the function while captureing the returning stdout and stderr streams. 

        Assume that $dacDinDir, $DestFile, $ConnectionString are all set to sueful values. 

        $EXEPath = "$dacBinDir\SqlPackage.exe"
        $options = "/Action:Extract /OverwriteFiles:True /tf:$DestFile /scs:$ConnectionString"

        $return = Start-MyProcess -EXEPath  $EXEPath -options $options

        if ($logLevel -eq "Debug"){
            #Only show the stdout stream if we are in debugging logLevel
            $return.stdout
        }
        if ($return.sterr -ne $null){
            Write-Log "$($return.sterr)" Warning
            Write-Log "There was an error of some type. See warning above for more info" Error
        }
    .OUTPUTS
        A object with 3 properties, stdout, stderr, and ExitCode. stdout and stderr are text streams that conatian output from the process. Generally if (stderr -eq $null) then there was some sort of error. You can also parse stdout to find errors, or check the ExitCode for non-success
       
    #>
[CmdletBinding()]
	param( 
		[Parameter(ValueFromPipeline=$True, Position=0)] [string] $EXEPath
,[string] $options
,[Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Warning"
		)
																					   

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $currentLogLevel = Get-LogLevel
    if ([string]::IsNullOrEmpty($logLevel)){
        $logLevel = "Warning"
    }
    Set-LogLevel $logLevel
    $EXE = $EXEPath.Substring($EXEPath.LastIndexOf("\")+1,$EXEPath.Length-$EXEPath.LastIndexOf("\")-1)
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "`"$EXEPath`""
    $pinfo.Arguments = "$options"
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true

    # Create a process object using the startup info
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo

    Write-Log "Executing the following command" Debug
    Write-Log "$($pinfo.FileName) $($pinfo.Arguments)" Debug
    try{
        $process.Start() | Out-Null
    }
    catch{
        Write-Log "****Process errors****" Warning
        Write-Log "$($_.Exception.ToString())"  Warning
        Write-Log "Error calling $EXE. See previous warning(s) for error text. Try running the script with a lower logLevel variable to collect more troubleshooting information. Aborting script" Error -ErrorAction Stop
        
    }

    if (!$process.HasExited) {
        # Wait a while for the process to exit
	    Write-Log "$EXE is not done, let's wait 5 more seconds"
	    sleep -Seconds 5
    }
    Write-Log "$EXE has completed."

    Set-LogLevel $currentLogLevel
    # get output from stdout and stderr
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()

    $stdOutput = New-Object -TypeName PSObject
    $stdOutput | Add-Member –MemberType NoteProperty –Name stderr –Value $stderr
    $stdOutput | Add-Member –MemberType NoteProperty –Name stdout –Value $stdout
    $stdOutput | Add-Member -MemberType NoteProperty -Name exitCode -value $process.ExitCode

    return $stdOutput
}export-modulemember -Function Start-MyProcess
function Get-GitBranchesToDelete{
<#
    .Synopsis
      Identifies which local git branches do not have a valid upstream branch. It does this by calling git fetch -p --dry-run
    .DESCRIPTION
      Using the git command: git fetch -p --dry-run, this script reads the output of the git comamnd, and parses out the branches that have been deleted in the upstream
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
    .PARAMETER gitfetchOutputPath
        I have not figured out how to read the output (as an array of strings) from git fetch -p --dry-run directly in Powershell. The hacky workaround is to write stderr to a file, then read the file. This lets me iterate through each line and arse the output. This parameter is the path to the file that will hold this data. It will be created if it does not exist. Default value is C:\temp\gitFetchOutput.txt
    .PARAMETER remoteName
        The remote name that we are looking for when parsing out the response. IE. Which remote are we looking for deleted branches from. default is "origin"

    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string]$gitfetchOutputPath = "C:\temp\gitFetchOutput.txt"
,[string] $remoteName = "origin")

Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

if (Test-Path $gitfetchOutputPath){
    Remove-Item $gitfetchOutputPath
    "" | Add-Content -Path $gitfetchOutputPath
}
else{
    New-Item $gitfetchOutputPath -ItemType File | Out-Null
}

$allOutput = & git fetch -p --dry-run 2>&1
$allOutput | ?{ $_ -is [System.Management.Automation.ErrorRecord] } | Add-Content -Path $gitfetchOutputPath

$branchName = $null
$outBranches = @()
foreach ($line in Get-Content $gitfetchOutputPath){
    if ([string]::IsNullOrEmpty($line)-or ($line -notlike "*$remoteName/*") -or ($line.Substring($line.IndexOf("[")+1,7) -ne "deleted")){continue}
    Write-Log "Parsing the line: $line" Debug
    
    $branchName = $line.Substring($line.IndexOf("$remoteName/")+7)
    $outBranches += $branchName
}

$outBranches
}export-modulemember -Function Get-GitBranchesToDelete
Function Get-GitBranchesComparedToRemote{
<#
    .Synopsis
      WIP, this script is going to check the status of all your local branches and compare it with the origin (TFS server) to see which local branches are out of sync (and by how much) with the origi
    .PARAMETER
        branchName
       if specified, only check the status of this branch. If left as the default, it will compare all branches
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string] $branchName = $null
,[string] $remoteName = "origin")

Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

if ([string]::IsNullOrEmpty($branchName)){
    $branches = git branch
}
else{
    $branches = $branchName
    
}
$branchesToDelete = Get-GitBranchesToDelete
$outputs = @()

foreach ($branch in $branches){
    
    $branchName = $($($branch.Replace(' ','')).Replace('*',''))
    $output = New-Object -TypeName PSObject
    $output | Add-Member –MemberType NoteProperty –Name branchName –Value $branchName
    $result = git branch -r 
    if (!($result -like "*$branchName*")){
        $output | Add-Member –MemberType NoteProperty –Name hasUpstream –Value $false
        Write-Log "Could not find a branch named $branchName in your remote ref list. Perhaps the branch has not been pushed up to the remote?" Debug
    }
    else {
        $result = $null
        $output | Add-Member –MemberType NoteProperty –Name hasUpstream –Value $true

        if ($branchName -in $branchesToDelete){
            $output | Add-Member –MemberType NoteProperty –Name upstreamRefValid –Value $false
        }
        else{
            $output | Add-Member –MemberType NoteProperty –Name upstreamRefValid –Value $true
        }
        
        Write-log "git rev-list $remoteName/master..$remoteName/$branchName" Debug
        $result = git rev-list $remoteName/master..$remoteName/$branchName
        $output | Add-Member –MemberType NoteProperty –Name aheadRemoteMaster –Value $($result.count)
        Write-Log "Remote branch named '$branchName' is: $($result.count) ahead of remote master" Debug
        $result = $null
        Write-Log "git rev-list $remoteName/$branchName...$remoteName/master" Debug
        $result = git rev-list $remoteName/$branchName...$remoteName/master
        $output | Add-Member –MemberType NoteProperty –Name behindRemoteMaster –Value $($result.count)
        Write-Log "Remote branch named '$branchName' is: $($result.count) behind remote master" Debug
        Write-Log "*******" Debug
        Write-log "git rev-list heads/$branchName...$remoteName/$branchName" Debug
        $result = git rev-list heads/$branchName...$remoteName/$branchName
        $output | Add-Member –MemberType NoteProperty –Name aheadRemote –Value $($result.count)
        Write-Log "Local branch named '$branchName' is: $($result.count) ahead of remote" Debug
        $result = $null
        Write-Log "git rev-list $remoteName/$branchName...heads/$branchName" Debug
        $result = git rev-list $remoteName/$branchName...heads/$branchName
        $output | Add-Member –MemberType NoteProperty –Name behindRemote –Value $($result.count)
        Write-Log "Local branch named '$branchName' is: $($result.count) behind remote" Debug

        $outputs += $output
    }  
}

$outputs
}export-modulemember -Function Get-GitBranchesComparedToRemote
Function Invoke-GitFetchForSubDirectories{
param([Parameter(position=0)][string] $directoryToRecurse = $null
,[Parameter(position=1)][int] $directoryRecurseDepth = 1
,[Parameter(position=2)][string] $remote = $null)

if ([string]::IsNullOrEmpty($directoryToRecurse)){$directoryToRecurse = Get-Location}
$origDirectory = Get-Location

$subDirs = Get-ChildItem $directoryToRecurse -Recurse -Directory -Depth $directoryRecurseDepth
$gitDirs = @()
foreach ($dir in $subDirs){
    Write-Log "Attempting to fetch in $($dir.FullName)" Debug
    cd $($dir.FullName)
    if ([string]::IsNullOrEmpty($remote)){git fetch --all}
    else{git fetch $remote}
    
}

cd $origDirectory
}Export-modulemember -Function Invoke-GitFetchForSubDirectories