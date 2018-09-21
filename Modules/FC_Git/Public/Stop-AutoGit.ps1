function Stop-AutoGit {
  $jobs = Get-MyJobs | Where-Object { $_.Name -like "$(Get-JobPrefix)AutoGit*" }
  Write-Log "Returned $($jobs.Count) auto git jobs that will be removed"
  $jobs | Remove-Job -Force

} Export-ModuleMember -Function Stop-AutoGit
