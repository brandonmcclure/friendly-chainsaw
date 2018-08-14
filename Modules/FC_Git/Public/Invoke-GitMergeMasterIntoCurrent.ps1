function Invoke-GitMergeMasterIntoCurrent {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(ParameterSetName = 'path')] [string]$repoPath = $null,
    #[Parameter(ParameterSetName = 'name')] [string]$repoName,
    [string]$branchName = 'master'
  )

  if ([string]::IsNullOrEmpty($repoPath)) {
    $repoPath = Get-Location
  }
  try {
    $CurrentBranch = Get-GitBranch
    Sync-GitRepo -branchName $branchName -repoPath $repoPath

    $result = $null
    $result = Start-MyProcess -EXEPath 'git' -Options "checkout $CurrentBranch"

    if ($result.stdout -like '*error*') {
      Write-Log "There was an error:" Warning
      $result.stdout
    }

    $result = $null
    $result = Start-MyProcess -EXEPath 'git' -Options "merge $branchName"

    if ($result.stdout -like '*error*') {
      Write-Log "There was an error:" Warning
      $result.stdout
    }
  }
  catch {
  }
  finally {
  }
} Export-ModuleMember -Function Invoke-GitMergeMasterIntoCurrent
