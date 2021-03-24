function Get-BackupJob{
	param(
		[string]$Name,
		[switch]$OpenDestinationPath,
		[switch]$OpenSourcePath
	)

	$outObj = $Script:BackupJobs
	if(-not [string]::IsNullOrEmpty($Name)){
		$outObj = $outObj | Where {$_.Name -eq $Name}
	}
Write-Output $outObj
if($OpenDestinationPath -or $OpenSourcePath){
	$objCount = $outObj | Measure-Object | select -ExpandProperty Count
	if($objCount -ge 5){
		Write-Log ""
	}
	$jobCounter = 0
	foreach($i in $outObj){
		$jobCounter++
		if($jobCounter -ge 5){return}
		if($OpenSourcePath){Invoke-Item $i.SourcePath}
		if($OpenDestinationPath){Invoke-Item $i.DestinationPath}
	}
}

}Export-ModuleMember -Function Get-BackupJob