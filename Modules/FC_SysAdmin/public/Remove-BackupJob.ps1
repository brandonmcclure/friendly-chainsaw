function Remove-BackupJob{
<#
.Synopsis
	Removes a backup job from the database
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(ValueFromPipeline)]$job)

	begin{
		if([string]::IsNullOrEmpty($job)){Write-Log "You must pass a job parameter"  Error -ErrorAction Stop}
	}

	process{
		$Script:BackupJobs = $($Script:BackupJobs | where-object {$_.SourcePath -ne $job.SourcePath -and $_.DestinationPath -ne $job.DestinationPath})
		$Script:BackupJobs | ConvertTo-Json -Depth 5 | Set-Content $Script:BackupJobPath
	}

}Export-ModuleMember -Function Remove-BackupJob