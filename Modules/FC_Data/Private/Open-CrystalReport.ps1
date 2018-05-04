function Open-CrystalReport{
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(ValueFromPipeline,position=0)][string]  $pathToReport = $null)

if ([string]::IsNullOrEmpty($pathToReport)){
    Write-Log "Please pass a value to pathToReport parameter" Error -ErrorAction Stop
}
elseif (!(Test-Path $pathToReport)){
    Write-Log "Please pass a valid path to the pathToReport parameter" Error -ErrorAction Stop
}
$report = New-Object CrystalDecisions.CrystalReports.Engine.ReportDocument 

$report.Load($pathToReport)

Write-Output $report
}Export-ModuleMember -Function Open-CrystalReport