function Get-PrometheusPusher{
    [OutputType([Prometheus.MetricPusher])]
    param([switch]$logError,$jobType = "batch",$scriptName)
    
    Add-Type -AssemblyName Prometheus.NetStandard -ErrorAction Stop
    Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
    
    if([string]::IsNullOrEmpty($script:PrometheusBasicAuthUser)){
        throw "Could not get prometheus pusher because the basic auth credentials have not been set. Run Set-PrometheusBasicAuthCredentials first"
    }
    $headerValue = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$( ConvertFrom-SecureString -AsPlainText -SecureString ($script:PrometheusBasicAuthUser | ConvertTo-SecureString)):$( ConvertFrom-SecureString -AsPlainText -SecureString ($script:PrometheusBasicAuthPassword | ConvertTo-SecureString))"));
    
    $httpClient = New-Object -TypeName System.Net.Http.HttpClient -ErrorAction Stop
    $httpClient.DefaultRequestHeaders.Clear()
    $httpClient.DefaultRequestHeaders.Authorization = New-object -TypeName System.Net.Http.Headers.AuthenticationHeaderValue -ArgumentList "Basic", $headerValue
    
    
    $options = New-Object -TypeName Prometheus.MetricPusherOptions
    $options.Endpoint = $script:PrometheusPushURL
    
$code = @'
using System;
public class PrometheusCallbackLogging
{    
    public static void Callback(object obj)    
    {         
        Console.WriteLine(obj.ToString());    
    }
}
'@
    
    if (-not ([System.Management.Automation.PSTypeName]'PrometheusCallbackLogging').Type)
    {
        Add-Type -TypeDefinition $code -Language CSharp
    }
    
    $method = [PrometheusCallbackLogging].GetMethod("Callback") 
    $delegate = [System.Delegate]::CreateDelegate([System.Action[Object]], $null, $method)
    
    if($logError){
        $options.OnError = $delegate
    }
    
    
    if([string]::IsnullOrEmpty($scriptName)){
        $scriptName = (Get-PSCallStack | Select-Object -Skip 1 -First 1 | Where-Object { $_.FunctionName -eq '<ScriptBlock>' } | select -ExpandProperty Command) -replace '.ps1',''
    }
    if([string]::IsnullOrEmpty($scriptName)){
        Write-Log "Cannot set the scriptName label" Error -ErrorAction Stop
    }
    
    $options.Instance = $env:COMPUTERNAME
    $options.Job = "$(Get-Date -Format 'yyyy.MM.dd_HH.mm.ss')-$(New-Guid)"
    if([string]::IsNullOrEmpty($options.Job)){
        $options.Job = "adhoc"
    }
    $options.HttpClientProvider = {$httpClient}

    $staticLabels =  New-Object 'System.Collections.Generic.Dictionary[String,String]'
    $staticLabels.Add("environment","adhoc")
    $staticLabels.Add("script_name",$scriptName)
    $staticLabels.Add("job_type",$jobType)
    
    if([Prometheus.Metrics]::DefaultRegistry.StaticLabels.Count -eq 0){
        [Prometheus.Metrics]::DefaultRegistry.SetStaticLabels($staticLabels );
    }
    
    
    $outObj = New-Object -TypeName Prometheus.MetricPusher -ArgumentList $options
    
    $outObj.Start()
    
    $instanceCount = New-PrometheusMetricGauge -metricName "instance_start_total" -MetricDescription "Number of instances that have started"
    $instanceCount.set(1);
    $instanceCount.Publish();
    sleep 5
    $outObj.Stop()
    
    Write-Output $outObj
    }export-ModuleMember -function Get-PrometheusPusher