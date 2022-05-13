function Invoke-PrometheusMetricFile{
param($metrics,$textFileDir)

$scriptName = ""
if([string]::IsnullOrEmpty($scriptName)){
    $scriptName = Get-CallingScript
}
if([string]::IsnullOrEmpty($scriptName)){
    Write-Log "Cannot set the scriptName label" Error -ErrorAction Stop
}

if([string]::IsnullOrEmpty($textFileDir)){
    Write-Log "Please specify a textFileDir" Error -ErrorAction Stop
}

$Instance = $env:COMPUTERNAME

$textFilePath = "$textFileDir\$($scriptName).prom"

if(-not (Test-Path $textFileDir)){
    New-Item -Path $textFileDir -ItemType Directory -Force -ErrorAction Stop #| Out-Null
}

$oldMetrics = Get-PrometheusMetricFile -path $textFilePath




$metricData = ""
foreach($metric in $metrics){
    $staticLabels = @(
    "script_name=`"$scriptName`"",
    "job_type=`"$JobType`""
)
	if($metric.name -in $oldMetrics.name){
		Write-Log "Metric already exists" debug
	}
    $Name = $metric.Name
    $Description = $metric.Description
    $type = $metric.type
    $value = $metric.value

    foreach ($label in $metric.labels){
        $staticLabels += $label
    }

    $staticLabelsString = "{ $($staticLabels -join ',') }"

$metricData += "# HELP $name $Description
# TYPE $Name $type
$Name $staticLabelsString $value
" -replace "`r`n","`n"

}

Set-Content -Value "$metricData" -Path $textFilePath -NoNewline -Encoding UTF8
}