function Invoke-GitFetchForSubDirectories {
  param([Parameter(Position = 0)] [string]$directoryToRecurse = $null
    ,[Parameter(Position = 1)] [int]$directoryRecurseDepth = 1
    ,[Parameter(Position = 2)] [string]$remote = $null)

  if ([string]::IsNullOrEmpty($directoryToRecurse)) { $directoryToRecurse = Get-Location }
  $origDirectory = Get-Location

  $subDirs = Get-ChildItem $directoryToRecurse -Recurse -Directory -Depth $directoryRecurseDepth
  $gitDirs = @()
  foreach ($dir in $subDirs) {
    Write-Log "Attempting to fetch in $($dir.FullName)" Debug
    Set-Location $($dir.FullName)
    if ([string]::IsNullOrEmpty($remote)) { git fetch --all }
    else { git fetch $remote }

  }

  Set-Location $origDirectory
} Export-ModuleMember -Function Invoke-GitFetchForSubDirectories