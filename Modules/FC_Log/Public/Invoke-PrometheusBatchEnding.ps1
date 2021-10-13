function Invoke-PrometheusBatchEnding{
    param($SLO_InstanceShouldRunEveryXSeconds)

    if([string]::IsNullOrEmpty($SLO_InstanceShouldRunEveryXSeconds)){
        Write-Log "Cannot send prometheus batch ending. Please pass the target SLO for how many seconds we expect this batch job to run via -SLO_InstanceShouldRunEveryXSeconds" Error -ErrorAction Stop
    }
    $unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
    $unixEpochTimer = [int]([DateTime]::UtcNow - (new-object DateTime 1970, 1, 1, 0, 0, 0,([DateTimeKind]::Utc))).TotalSeconds

    # Our SLO is to run an instance of this script every hour, 24/7
    $sloGauge = New-PrometheusMetricGauge -metricName "instance_last_complete_slo_target_seconds" -MetricDescription "The target SLO threshold for how frequently we are planning on running this batch (in seconds)."
    $sloGauge.set($SLO_InstanceShouldRunEveryXSeconds);
    $sloGauge.Publish();

    $timeGauge = New-PrometheusMetricGauge -metricName "instance_last_complete_epoch_seconds_diff" -MetricDescription "The last time this job finished"
    $timeGauge.set($unixEpochTimer);
    $timeGauge.Publish();
}