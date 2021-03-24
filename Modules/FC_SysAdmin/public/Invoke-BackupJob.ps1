function Invoke-BackupJob{
	param([Parameter(ValueFromPipeline)]$job)
	
	if([string]::IsNullOrEmpty($job)){Write-Log "You must pass a job parameter"  Error -ErrorAction Stop}
if ($job.BackupProvider.Name -eq "pwsh"){
	Invoke-IncrementalFileBackup -SourceDirectory $job.SourcePath -BackupToRootPath $job.DestinationPath -BackupName $job.name
}
else{throw "I do not know how to run that backup provider"}
}Export-ModuleMember -Function Invoke-BackupJob