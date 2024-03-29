Class PromTrackerItems : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {

		$mds = @()
		$t = Get-Content "$env:USERPROFILE\.friendly-chainsaw\tracker.json" -raw | ConvertFrom-Json -ErrorAction Stop
		foreach ($i in $t){
			$mds += $i
		}
        return [string[]] ($mds | select -expandProperty name)
    }
}
function Invoke-PromTracker{
param(
	[ValidateSet([PromTrackerItems])]
	$trackingType,
	[switch]$ShowMe,
	[switch]$OpenMe
)
$metrics = @()
import-module FC_Log -force

if(-not (Test-Path "$env:USERPROFILE\.friendly-chainsaw\tracker.json")){
	New-Item "$env:USERPROFILE\.friendly-chainsaw\tracker.json"
}
if($OpenMe){
	ii "$env:USERPROFILE\.friendly-chainsaw\tracker.json"
	return
}
$mds = @()
$t = Get-Content "$env:USERPROFILE\.friendly-chainsaw\tracker.json" -raw | ConvertFrom-Json -ErrorAction Stop
foreach ($i in $t){
	$mds += $i
}
$mdCount = $mds | Measure-Object | Select-Object -ExpandProperty Count


Write-Log "Found $mdCount tracked things" Debug
if($ShowMe){
	Write-Output ($mds | Sort-Object LastTrackedPromEpoch -Descending)
	return
}
if([string]::IsNullOrEmpty($trackingType)){
	Write-Log "I cannot do this without a trackingType specified" Error -ErrorAction Stop
}

if( [string]::IsNullOrEmpty($script:PrometheusMetricPath)){
	Write-Log "You have not specified the Prometheus Metric Path with the Invoke-PrometheusConfig function" Error -ErrorAction Stop
}

$StaticLabels = @("SupportTeam=`"Unknown`"")

if($trackingType -notin ($mds | select -ExpandProperty name)){
	
	Write-Log "Tracking a new thing: $trackingType" Warning
	$sloTime = Read-Host -Prompt "Enter the number of seconds we expect this thing to be tracked"
	$mds += @{name=$trackingType; slofrequency=$sloTime}
}


foreach($md in $mds){
	$instanceLabel = $StaticLabels
	$instanceLabel += @("tracker=`"$($md.name)`"")
	if($trackingType -in $md.name){
		
		$timestamp = Get-PrometheusEpochTimeStamp
		$md.lastTrackedPromEpoch = $timestamp
	}
	$metrics += @(
		,@{Name="$($script:PrometheusDomain)_tracker"; Description="General tracker";type="gauge"; value=$md.lastTrackedPromEpoch;labels=$instanceLabel}
		,@{Name="$($script:PrometheusDomain)_tracker_slo_seconds"; Description="Service level object for how frequently this general tracker should run";type="gauge"; value="$($md.slofrequency)";labels=$instanceLabel}
	)
}

$json = $mds | ConvertTo-Json -depth 5
$json | Set-Content "$env:USERPROFILE\.friendly-chainsaw\tracker.json"

Invoke-PrometheusBatchEnding -textFileDir $script:PrometheusMetricPath -SLO_InstanceShouldRunEveryXSeconds 14400 -domain $script:PrometheusDomain -metrics $metrics

}