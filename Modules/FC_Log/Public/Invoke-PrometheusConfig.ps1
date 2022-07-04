function Invoke-PrometheusConfig{
	param(
		$promDomain, $promMetricPath
	)
	Write-Log "Setting up Prometheus variables"

	if(-Not ([string]::IsNullOrEmpty($promDomain))){
		Write-Log 'Setting the $script:PrometheusDomain variable'
		$script:PrometheusDomain = $promDomain
	}

	if(-Not ([string]::IsNullOrEmpty($promMetricPath))){
		Write-Log 'Setting the $script:PrometheusMetricPath variable'
		$script:PrometheusMetricPath = $promMetricPath
	}

}