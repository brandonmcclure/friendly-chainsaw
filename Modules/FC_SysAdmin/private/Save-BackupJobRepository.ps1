function Save-BackupJobRepository{
	Set-Content -Path $Script:BackupJobPath -Value ($Script:BackupJobs | ConvertTo-Json)
}