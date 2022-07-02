function Invoke-PrometheusMetricFile{
param($metrics,$textFileDir,$scriptName)


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






$metricData = ""

$metricNames = $metrics | Select-Object Name,description,type -Unique
foreach($uniqueMetric in $metricNames){
    $metricData += "# HELP $($uniqueMetric.name) $($uniqueMetric.description)
# TYPE $($uniqueMetric.name) $($uniqueMetric.type)
"
    
    foreach($metric in ($metrics | where {$uniqueMetric.Name -eq $_.Name})){
        $staticLabels = @(
        "script_name=`"$scriptName`"",
        "job_type=`"$JobType`""
    )

        $Name = $metric.Name
        $Description = $metric.Description
        $type = $metric.type
        $value = $metric.value

        foreach ($label in $metric.labels){
            $staticLabels += $label
        }

        $staticLabelsString = "{ $($staticLabels -join ',') }"

    $metricData += "$Name $staticLabelsString $value
" -replace "`r`n","`n"

    }
}
Set-Content -Value "$metricData" -Path $textFilePath -NoNewline -Encoding UTF8
}