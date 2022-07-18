function Get-PrometheusEpochTimeStamp{
	$unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
    $unixEpochTimer = [int]([DateTime]::UtcNow - (new-object DateTime 1970, 1, 1, 0, 0, 0,([DateTimeKind]::Utc))).TotalSeconds

	Write-Output $unixEpochTimer.ToString()
}