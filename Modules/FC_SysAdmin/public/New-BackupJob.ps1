function New-BackupJob{
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		$Name
		,$SourcePath
		,$DestinationPath
		,[BackupProvider]$BackupProvider
	)
	
	if([string]::IsNullOrEmpty($Name)){
		Write-Error "You must pass a name" -ErrorAction Stop
	}
	foreach ($job in $Script:BackupJobs | where {$_.SourcePath -eq $SourcePath -and $_.DestinationPath -eq $DestinationPath} ){
		Write-Output $job
		Write-Log "There is already a backup job with those settings" Error -ErrorAction Stop
		
	}
	$newJob = New-Object BackupJob -ArgumentList $Name,$SourcePath,$DestinationPath,$BackupProvider
	$Script:BackupJobs += $newJob
	Write-Output $newJob

	Save-BackupJobRepository
	}Export-ModuleMember -Function New-BackupJob