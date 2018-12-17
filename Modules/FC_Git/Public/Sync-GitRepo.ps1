<#
    .Synopsis
      Performs a git fetch and pull from the master branch for the given repoPath
    .DESCRIPTION
      USed to programatically get an up to date programatic branch that is in sync with a remote


    #>
function Sync-GitRepo{

[CmdletBinding(SupportsShouldProcess=$true)] 
param(
  [Parameter(ParameterSetName='path')][string] $repoPath,
  [Parameter(ParameterSetName='name')][string] $repoName,
[string] $branchName = 'master'
)

if ([string]::IsNullOrEmpty($repoPath) -and [string]::IsNullOrEmpty($repoName)){
    Write-Log "please pass either the -repoPath or repoName parameters" Error
}
elseif([string]::IsNullOrEmpty($repoPath)){
$global:GitRepositories
    $repoPath = Get-GitRepositories
}
$oldLocation = Get-Location
function HandleSTdOut{
param([Parameter(ValueFromPipeline)][object] $processOutput)
process{
    Write-Log "stdOut: $( $processOutput.stdout)" Verbose
    Write-Log "stderr: $( $processOutput.stderr)" Verbose
  
    if ($processOutput.stdout -like '*error*'){
        Write-Log "There was an error: $($processOutput.stdout)" Error -ErrorAction Stop
        
    }
    elseif ($processOutput.stderr -like '*error*'){
        Write-Log "There was an error: $($processOutput.stderr)" Error -ErrorAction Stop
        
    }
}
}
try{
    Set-Location $repoPath
    if ((Get-GitBranch) -ne $branchName){
        Start-MyProcess -EXEPath 'git' -options "checkout $branchName" | HandleSTdOut
    }
    Start-MyProcess -EXEPath 'git' -options "fetch" | HandleSTdOut
    Start-MyProcess -EXEPath 'git' -options "pull"  | HandleSTdOut
}
catch{
}
finally{
    Set-Location $oldLocation
}
} Export-ModuleMember -Function Sync-GitRepo