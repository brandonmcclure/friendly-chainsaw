function Remove-GitBranch{
<#
    .Synopsis
      Please give your script a brief Synopsis,
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER remoteName
        if set, will push --delete the branch from the remote specified
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       What sort of pipeline inputdoes this expect?
    .OUTPUTS
       What sort of pipeline output does this output?
    .LINK
       www.google.com
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string] $branchName,
  [Parameter(ParameterSetName='path')][string] $repoPath,
  [Parameter(ParameterSetName='name')][string] $repoName,
[string] $remoteName = 'origin')

if ([string]::IsNullOrEmpty($repoPath) -and [string]::IsNullOrEmpty($repoName)){
    Write-Log "please pass either the -repoPath or repoName parameters" Error
}
elseif([string]::IsNullOrEmpty($repoPath)){
    Write-Log "Please pass a valid repo path to $repoPath" Error -ErrorAction Stop
}
$oldLocation = Get-Location

try{
    Set-Location $repoPath
    Write-Log "git branch -D $branchName" Verbose
    $result = Start-MyProcess -EXEPath 'git' -options "branch -D $branchName"
    Write-Log "stderr: $($result.stderr)" Verbose
    Write-Log "stdout: $($result.stdout)" Verbose

    if (-not [string]::IsNullOrEmpty($remoteName)){
        Write-Log "git push $remoteName --delete $branchName" Verbose
        $result = Start-MyProcess -EXEPath 'git' -options "push $remoteName --delete $branchName"
        Write-Log "stderr: $($result.stderr)" Verbose
        Write-Log "stdout: $($result.stdout)" Verbose
    }
}
catch{
    throw
}
finally{
    Set-Location $oldLocation
}

} Export-ModuleMember -Function Remove-GitBranch