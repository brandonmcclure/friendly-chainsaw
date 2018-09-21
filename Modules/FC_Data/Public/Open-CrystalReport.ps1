function Open-CrystalReport{
<#
    .Synopsis
      Opens a Crystal Report file (.rpt) and passes it through the pipeline as part of a 
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       A file path to a report file to load
    .OUTPUTS
       A CrystalDecisions.CrystalReports.Engine.ReportDocument object
    .LINK
       www.google.com
    #>
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