function Read-BackupJobRepository{
	$Script:BackupJobs = Get-Content $Script:BackupJobPath | ConvertFrom-Json -Depth 5
}Export-ModuleMember -Function Read-BackupJobRepository