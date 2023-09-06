function New-PrometheusMetricCounter{
    [OutputType([Prometheus.Metrics])]
    param(
        $MetricDescription = "Change Me",
        $domain = "friendlychainsaw",
        $subdomain = "default",
        $metricName
        )

        $config = New-Object 'Prometheus.CounterConfiguration'    
        $config.SuppressInitialValue = $true

		$scriptName = Get-PSCallStack | Select-Object -Skip 1 -First 1 | Where-Object { $_.FunctionName -eq '<ScriptBlock>' } | select -ExpandProperty Command
		
		if ([String]::IsNullOrEmpty($scriptName)){
			$scriptName = Get-PSCallStack | Select-Object -Skip 1 -First 1 | select -ExpandProperty Command
		}

		if ([String]::IsNullOrEmpty($scriptName)){
			$scriptName = "Adhoc script"
		}
		$jobName = $scriptName -replace '.ps1',''

		$labels = New-Object System.Collections.Generic.Dictionary"[String,String]"
		$labels.Add("FileName",$jobName)
		$config.StaticLabels = $labels

    Write-Output ([Prometheus.Metrics]::CreateCounter("$($domain)_$($subdomain)_$metricName",$MetricDescription,$config))
}Export-ModuleMember -Function New-PrometheusMetricCounter