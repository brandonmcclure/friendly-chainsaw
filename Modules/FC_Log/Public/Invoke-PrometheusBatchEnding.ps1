function Invoke-PrometheusBatchEnding{
    param(
        $textFileDir = "C:\mcd\promMetrics",
    $SLO_InstanceShouldRunEveryXSeconds,
    $SupportTeam = "Unsupported",
    $domain = 'mcd',
    $metrics,
    $scriptName
    )
    $JobType = 'batch'
    if([string]::IsNullOrEmpty($SLO_InstanceShouldRunEveryXSeconds)){
        Write-Log "Cannot send prometheus batch ending. Please pass the target SLO for how many seconds we expect this batch job to run via -SLO_InstanceShouldRunEveryXSeconds" Error -ErrorAction Stop
    }

    $labels = @("SupportTeam=`"$SupportTeam`"")
    $metrics += @(
        @{Name="$($domain)_data_instance_last_complete_epoch_seconds_diff"; Description="The last time this job finished";type="gauge"; value="$(Get-PrometheusEpochTimeStamp)";labels=$labels}
        ,@{Name="$($domain)_data_instance_last_complete_slo_target_seconds"; Description="The target SLO threshold for how frequently we are planning on running this batch (in seconds).";type="gauge"; value="$($SLO_InstanceShouldRunEveryXSeconds.ToString())";labels=$labels}
    )

    
    Invoke-PrometheusMetricFile -metrics $metrics -textFileDir $textFileDir -scriptName $scriptName
    
}