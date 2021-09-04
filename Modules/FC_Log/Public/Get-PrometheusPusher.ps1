function Get-PrometheusPusher{

[OutputType([Prometheus.MetricPusher])]
param([switch]$logError)

Add-Type -AssemblyName Prometheus.NetStandard -ErrorAction Stop


$headerValue = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$( ConvertFrom-SecureString -AsPlainText -SecureString ($script:PrometheusBasicAuthUser | ConvertTo-SecureString)):$( ConvertFrom-SecureString -AsPlainText -SecureString ($script:PrometheusBasicAuthPassword | ConvertTo-SecureString))"));
Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
$httpClient = New-Object -TypeName System.Net.Http.HttpClient -ErrorAction Stop

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


$scriptName = Get-PSCallStack | Select-Object -Skip 1 -First 1 | Where-Object { $_.FunctionName -eq '<ScriptBlock>' } | select -ExpandProperty Command

$jobName = $scriptName -replace '.ps1',''
$options.Instance = $env:COMPUTERNAME
$options.Job = $jobName
if([string]::IsNullOrEmpty($options.Job)){
    $options.Job = "ad hoc"
}
$options.HttpClientProvider = {$httpClient}

$outObj = $(New-Object -TypeName Prometheus.MetricPusher -ArgumentList $options)

$outObj.Start()

$instanceCount = New-PrometheusMetricCounter -metricName "instance_start_total" -MetricDescription "Number of instances that have started"
$instanceCount.Inc();
$instanceCount.Publish();

Write-Output $outObj
}export-ModuleMember -function Get-PrometheusPusher