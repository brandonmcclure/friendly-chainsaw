function Remove-BackupJob{
	param([Parameter(ValueFromPipeline)]$job)

	if([string]::IsNullOrEmpty($job)){Write-Log "You must pass a job parameter"  Error -ErrorAction Stop}

	$Script:BackupJobs = $($Script:BackupJobs | where {$_.SourcePath -ne $job.SourcePath -and $_.DestinationPath -ne $job.DestinationPath})
	$Script:BackupJobs | ConvertTo-Json -Depth 5 | Set-Content $Script:BackupJobPath
	

}Export-ModuleMember -Function Remove-BackupJob