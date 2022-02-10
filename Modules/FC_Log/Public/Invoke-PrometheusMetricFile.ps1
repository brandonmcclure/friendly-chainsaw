function Invoke-PrometheusMetricFile{
param($labels, $metrics,$textFileDir)

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
$Job = "$(Get-Date -Format 'yyyy.MM.dd_HH.mm.ss')_$(New-Guid)"

$textFilePath = "$textFileDir\$($scriptName)_$Job.prom"

if(-not (Test-Path $textFileDir)){
    New-Item -Path $textFileDir -ItemType Directory -Force -ErrorAction Stop #| Out-Null
}

$staticLabels = @(
    "script_name=`"$scriptName`"",
    "job=`"$Job`"",
    "job_type=`"$JobType`""
)

foreach ($label in $labels){
$staticLabels += $label
}

$staticLabelsString = "{ $($staticLabels -join ',') }"
$metricData = ""
foreach($metric in $metrics){
    $Name = $metric.Name
    $Description = $metric.Description
    $type = $metric.type
    $value = $metric.value




$metricData += "# HELP $name $Description
# TYPE $Name $type
$Name $staticLabelsString $value
" -replace "`r`n","`n"

}
Set-Content -Value "$metricData" -Path $textFilePath -NoNewline -Encoding UTF8
}