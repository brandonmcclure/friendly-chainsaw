
Import-Module fc_log -Force
Add-Type -AssemblyName Prometheus.NetStandard -ErrorAction Stop

#To use the Secret store: $creds = Get-Credential; New-Secret -Name 'pushgatewayBasicAuth' -vault friendlychainsaw -Secret $creds
#$creds = Get-Secret -Name "pushgatewayBasicAuth" -vault friendlychainsaw
Set-PrometheusBasicAuthCredentials -creds $creds
Set-PrometheusPushURL -Uri "https://pushgateway.mcd.com/metrics"
$promPusher = Get-PrometheusPusher
if([string]::IsNullOrEmpty($promPusher)){
    Write-Log "Could not get a Prom Pusher." Error -ErrorAction Stop
}
try{

$instanceCount = New-PrometheusMetricCounter -metricName "bad" -MetricDescription "Number of instances that have started"
$instanceCount.Inc();
$instanceCount.Publish();
        sleep 5
}
catch{
    throw
}
finally{
    $promPusher.Stop()
    $promPusher.Dispose()
}