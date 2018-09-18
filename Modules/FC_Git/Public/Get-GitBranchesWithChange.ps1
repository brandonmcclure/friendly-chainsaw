function Get-GitBranchesWithChange {
  param([string]$filePath)

  $oldLocation = Get-Location
  try {
    Set-Location (Split-Path $filePath)
    $lastMasterCommit = Get-GitLastCommit -Path $filePath -masterBranch
    $a = Get-Location
    git for-each-ref --format="%(refname:short)" refs/heads | Where-Object { $_ -ne "master" }
    $x = 0
  }
  catch {
    Set-Location $oldLocation
  }
  Set-Location $oldLocation
} Export-ModuleMember -Function Get-GitBranchesWithChange
