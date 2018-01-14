Function Invoke-TortoiseGit{
<#
    .SYNOPSIS
        Runs tortoiseGit UI from command line. View the TortoiseGit help documentation by running one of the following:
        
            tGit
            tGit help 
    .PARAMETER cmd
        Required

        The comamnd sent to tortoise git. run one of the following to view the TortoiseGit help documentation, and what valid options are.:

        tGit
        tGit help
        
    .PARAMETER path
        Optional
        Default = current directory

        The path passed to tortoise git. (for file renames, file log, or commiting individual directories or files.

    .EXAMPLE
        Shows the UI for a history of the file named myFile.txt in the current directory.

        tGit log .\myFile.txt

    .EXAMPLE
        Opens the commit UI for the current directory.

        tGit commit
    .LINKS
        https://ayende.com/blog/4749/executing-tortoisegit-from-the-command-line
#>
param([Parameter(position=0)] $cmd,
[Parameter(position=1)] $path
)
        $tGitPath = 'TortoiseGitProc.exe'
    
        if ([string]::IsNullOrEmpty($cmd)){
            & $tGitPath /command:help /path:.
        }
        else{
            if ([string]::IsNullOrEmpty($path)){
                & $tGitPath /command:$cmd /path:.
            }
            else{
                Write-log "Path: $path" Debug
                & $tGitPath /command:$cmd /path:$path
            }
        }


}Export-ModuleMember -Function Invoke-TortoiseGit -Alias tGit
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
Function Get-GitLastCommit{
<#
    .Synopsis
      Returns the full SHA1 commit hash for the most recent commit of the current branch
    .DESCRIPTION
      Will return an empty string if there is an error. 
    .PARAMETER path
        Optional
        Default: Null

        The path to the folder or file that you want to get the most recent commit from. Needs to be relative to the root of the repository. 

    .PARAMETER masterBranch
        Optional
        Default: $false

        This is kind of hacky so forgive me. If this switch is true, this will get the most recent commit hash from the local master branch, if false, it will look at the HEAD (or the current branch)
        I tried to parameterize this so you could choose which branch to get the commit, but I was getting errors which i believe was jsut the way I was formatting the invocation of the git.exe
       
    .EXAMPLE
        Get the most recent commit hash of the entire repository, for the current branch

        Get-GitLastCommit

        Output: dcef3a70cc28d9dfa058c8f86183cef6e78a6df5

    .EXAMPLE
        Get the most recent commit hash of a specific directory (named SSAS_TabularModels), for the current branch

        Get-GitLastCommit "SSAS_TabularModels"

        Output: 798bbd1d8d27b99ea27ff2e38e3ae86f4b02c317

    .EXAMPLE
        Get the most recent commit hash of a specific file in a subdirectory (named SSAS_TabularModels\.gitgnore on windows...), for the current branch

        Get-GitLastCommit "SSAS_TabularModels/.gitignore"

        Output: 6cb5d7854d5b81b407d475972ee602de9c7ddca3

    .EXAMPLE
        Get the most recent commit hash of a specific file in a subdirectory (named SSAS_TabularModels\.gitgnore on windows...), for the master branch

        Get-GitLastCommit "SSAS_TabularModels/.gitignore" -masterBranch

        Output: 6cb5d7854d5b81b407d475972ee602de9c7ddca3
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][string] $path = $null
,[Parameter(position=1)][switch] $masterBranch = $false
)

Write-Verbose "Current Location: $(Get-Location)"
$oldErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Stop"
try{
    if (!([string]::IsNullOrEmpty($path))){
    
        $path = $path -replace "\\","/"
        #This is crappy code... I was getting an error when I tried to parameterize this to allow you to specify what branch you want to get the last commit from. The error was :Path $path exists on disk but not in the index. 
        #When I outputted the call I am making, I was able to execute it on the command line just fine. Come find out the parameter that was located where "master" or "head" are is what was causing it. For the meantime, this works for my purposes. 
        #If theuser specifies, then get the commit from master. If not, get the commit of the current branch (HEAD)
        if ($masterBranch){
            Write-Verbose "git rev-parse master:""$path"""
            $gitLogOutput = & git rev-parse master:'"'$path'"'
        }
        else{
            Write-Verbose "git rev-parse head:""$path"""
            $gitLogOutput = & git rev-parse head:'"'$path'"'
        }
    }
    else{
        if ($masterBranch){
            Write-Verbose "git rev-parse master"
            $gitLogOutput = & git rev-parse master
        }
        else{
            Write-Verbose "git rev-parse HEAD"
            $gitLogOutput = & git rev-parse HEAD
        }
    
    }
}
catch{
    $gitLogOutput = ''
}
$ErrorActionPreference = $oldErrorAction
Write-Output $gitLogOutput
}Export-Modulemember -Function Get-GitLastCommit
Function Get-GitBranchesWithChange{
param([string] $filePath)

$oldLocation = Get-Location
try{
    Set-Location (Split-Path $filePath)
    $lastMasterCommit = Get-GitLastCommit -path $filePath -masterBranch
    $a = get-location
    git for-each-ref --format="%(refname:short)" refs/heads | where {$_ -ne "master"}
    $x = 0
}
catch{
    Set-Location $oldLocation
}
Set-Location $oldLocation
}Export-ModuleMember -Function Get-GitBranchesWithChange
Function Get-GitBranch{
Write-Log "$(Get-Location)" Warning
$a = git branch

write-output $a | where $_.substring(0,1) = '*'
}Export-ModuleMember -Function Get-GitBranch