$promMetricPath = "D:\metrics"
import-module fc_log -ErrorAction Stop -force
$StaticLabels = @("SupportTeam=`"Transfort`"")
$stopwatchTotal = [System.Diagnostics.Stopwatch]::StartNew()

$zipFileCount = Get-Random -Minimum 0 -Maximum 100
sleep $(Get-Random -Minimum 0 -Maximum 30)
$stopwatchTotal.Stop()
Write-Log "Script execution took: $($stopwatchTotal.Elapsed.TotalSeconds) seconds" Debug
$metrics = @(
        @{Name="city_data_instance_files_processed_total"; Description="How many files were processed";type="gauge"; value="$($zipFileCount.ToString())";labels=$StaticLabels}
        ,@{Name="city_data_instance_execution_time_seconds"; Description="How long did the job run for.";type="gauge"; value="$($stopwatchTotal.Elapsed.TotalSeconds.ToString())";labels=$StaticLabels}
    )

    
    Invoke-PrometheusMetricFile -metrics $metrics -textFileDir $promMetricPath -labels $labels

Invoke-PrometheusBatchEnding -textFileDir $promMetricPath -SLO_InstanceShouldRunEveryXSeconds 120 -domain 'city' -metrics $metrics
