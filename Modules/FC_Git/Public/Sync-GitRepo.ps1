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
try{
    Set-Location $repoPath
    if ((Get-GitBranch) -ne $branchName){
        $result = $null
        $result = Start-MyProcess -EXEPath 'git' -options "checkout $branchName"

        if ($result.stdout -like '*error*'){
            Write-Log "There was an error:" Warning
            $result.stdout
        }
    }
    $result = $null
    $result = Start-MyProcess -EXEPath 'git' -options "fetch"

    Write-Log $result.stdout
    Write-Log $result.stderr
    $result = $null
    $result = Start-MyProcess -EXEPath 'git' -options "pull"

    Write-Log $result.stdout
    Write-Log $result.stderr

}
catch{
}
finally{
    Set-Location $oldLocation
}
} Export-ModuleMember -Function Sync-GitRepo