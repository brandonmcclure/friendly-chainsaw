function Invoke-GitPushIntoAnotherBranch{
<#
    .Synopsis
      Merges a git branch into another branch. 
    .DESCRIPTION
      This is designed for programatic/automatic merging on branches using a dedicated repository on your computer. 
      It is also designed to be uses with a remote named 'origin', which is where it will checkout the branches from. I use this to keep my git branches merged into Integration branches in TFS.

      Merges the $fromBranchName branch into $intoBranchName       
    .EXAMPLE
        Takes my code in "MyCurrentFeatureBranch" and merges it into "SharedIntegrationBranch" which will trigger CI build/release and ensure my work is integrated with my other teammates. 

        Invoke-GitPushIntoAnotherBranch -autoRepoPath C:\source\Auto\MyRepo -fromBranchName "MyCurrentFeatureBranch" -intoBranchName "SharedIntegrationBranch"

    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string] $autoRepoPath
,[string] $intoBranchName = $null
,[string] $fromBranchName = $null)

if ([String]::IsNullOrEmpty($intoBranchName)){
    Write-Log "Please pass a intoBranchName" Error -ErrorAction Stop
}
if (!(Test-Path $autoRepoPath)){
    Write-Log "$autoRepoPath is not a valid path" Error -ErrorAction Stop
}
if ([String]::IsNullOrEmpty($fromBranchName)){
    Write-Log "No value specified for fromBranchName parameter, using the current branch name"
    $fromBranchName = Get-GitBranch
}
$currentLocation = Get-Location

function HandleSTdOut{
param([Parameter(ValueFromPipeline)][object] $processOutput)
process{
    Write-Log "stdOut: $( $processOutput.stdout)" Verbose
    Write-Log "stderr: $( $processOutput.stderr)" Verbose
  
    if ($processOutput.stdout -like '*error*' -or $processOutput.stdout -like '*fatal*' -or $processOutput.stdout -like '*failed*'){
        Write-Log "There was an error: $($processOutput.stdout)" Error -ErrorAction Stop
        
    }
    elseif ($processOutput.stderr -like '*error*' -or $processOutput.stderr -like '*fatal*'  -or $processOutput.stderr -like '*failed*'){
        Write-Log "There was an error: $($processOutput.stderr)" Error -ErrorAction Stop
        
    }
}
}
if ([String]::IsNullOrEmpty($fromBranchName)){
    Write-Log "Could not get the current branch name. Aborting" Error -ErrorAction Stop
}

try{
    Set-Location $autoRepoPath
    Write-Log "Fetching"
    Start-MyProcess -EXEPath 'git' -options "fetch" | HandleSTdOut
    Write-Log "Removing the branches if they already exist"
    Start-MyProcess -EXEPath 'git' -options "branch -D $intoBranchName" | Out-Null 
    Start-MyProcess -EXEPath 'git' -options "branch -D $fromBranchName" | Out-Null
    Write-Log "Checking out the branches"
    Start-MyProcess -EXEPath 'git' -options "checkout --track origin/$fromBranchName" | HandleSTdOut
    Start-MyProcess -EXEPath 'git' -options "pull" | HandleSTdOut
    Start-MyProcess -EXEPath 'git' -options "checkout --track origin/$intoBranchName" | HandleSTdOut
    Start-MyProcess -EXEPath 'git' -options "pull" | HandleSTdOut
    Write-Log "Performing the merge"
        Start-MyProcess -EXEPath 'git' -options "merge $fromBranchName" | HandleSTdOut
        Write-Log "Push the newly merged branch to the remote"
    Start-MyProcess -EXEPath 'git' -options "push" | HandleSTdOut
    
    

}
catch{
throw

}
finally{
    Write-Log "Cleaning up"
    Start-MyProcess -EXEPath 'git' -options "reset --hard HEAD --" | Out-Null
    Start-MyProcess -EXEPath 'git' -options "checkout master" | Out-Null 
    Start-MyProcess -EXEPath 'git' -options "pull" | Out-Null
    Start-MyProcess -EXEPath 'git' -options "branch -D $intoBranchName" | Out-Null 
    Start-MyProcess -EXEPath 'git' -options "branch -D $fromBranchName" | Out-Null
    Set-Location $currentLocation
}
} Export-ModuleMember -Function Invoke-GitPushIntoAnotherBranch