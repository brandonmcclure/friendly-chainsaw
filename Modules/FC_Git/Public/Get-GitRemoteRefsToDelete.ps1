function Get-GitRemoteRefsToDelete{
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
param([string]$gitfetchOutputPath = "$env:TEMP\gitFetchOutput.txt"
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

Write-Output $outBranches
}export-modulemember -Function Get-GitRemoteRefsToDelete