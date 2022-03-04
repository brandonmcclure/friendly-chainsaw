function Invoke-PrometheusBatchEnding{
    param(
        $textFileDir = "C:\mcd\promMetrics",
    $SLO_InstanceShouldRunEveryXSeconds,
    $SupportTeam = "Unsupported"
    )
    $JobType = 'batch'
    if([string]::IsNullOrEmpty($SLO_InstanceShouldRunEveryXSeconds)){
        Write-Log "Cannot send prometheus batch ending. Please pass the target SLO for how many seconds we expect this batch job to run via -SLO_InstanceShouldRunEveryXSeconds" Error -ErrorAction Stop
    }
    $unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
    $unixEpochTimer = [int]([DateTime]::UtcNow - (new-object DateTime 1970, 1, 1, 0, 0, 0,([DateTimeKind]::Utc))).TotalSeconds

    $metrics = @(
        @{Name="mcd_data_instance_last_complete_epoch_seconds_diff"; Description="The last time this job finished";type="gauge"; value="$($unixEpochTimer.ToString())"}
        ,@{Name="mcd_instance_last_complete_slo_target_seconds"; Description="The target SLO threshold for how frequently we are planning on running this batch (in seconds).";type="gauge"; value="$($SLO_InstanceShouldRunEveryXSeconds.ToString())"}
    )

    $labels = @("SupportTeam=`"$SupportTeam`"")
    Invoke-PrometheusMetricFile -metrics $metrics -textFileDir $textFileDir -labels $labels
    
}