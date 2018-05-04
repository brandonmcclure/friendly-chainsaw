Function Change-CRDataSourceConnection{
<#
    .Synopsis
      Please give your script a brief Synopsis,
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       What sort of pipeline inputdoes this expect?
    .OUTPUTS
       What sort of pipeline output does this output?
    .LINK
       www.google.com
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(ValueFromPipeline,position=0)][CrystalDecisions.CrystalReports.Engine.ReportDocument]  $report
,[string] $serverName = $null
,[string] $databaseName = $null
)
Load-CrystalDecisionAssemblies

if ([string]::IsNullOrEmpty($serverName)){
    Write-Log "Please pass a value to the serverName parameter" -ErrorAction Stop
}
if([string]::IsNullOrEmpty($databaseName)){
    Write-Log "Please pass a value to the databaseName parameter" -ErrorAction Stop
}

$connectionInfo = $report.Database.Tables[0].LogOnInfo.ConnectionInfo;
$connectionInfo.ServerName = $serverName
$connectionInfo.DatabaseName = $databaseName
$connectionInfo.IntegratedSecurity = $false

$tableLogOnInfo = New-Object CrystalDecisions.Shared.TableLogOnInfo 
$tableLogOnInfo.ConnectionInfo = $connectionInfo

Write-Log "Setting the connection at the report level"
$report.DataSourceConnections[0].SetConnection($serverName, $databaseName, $true)

Write-Log "There are $($report.Database.Tables | Measure-Object | Select -ExpandProperty Count) tables in the base report"
foreach ($table in $report.Database.Tables){
 
    Write-Log "Setting the connection for the $($table)"
    $table.ApplyLogOnInfo($tableLogOnInfo)

}

Write-Log "There are $($report.Subreports | Measure-Object | Select -ExpandProperty Count) subreports in the base report"
foreach ($subReport in $report.Subreports){
    Write-Log "There are $($subReport.Database.Tables | Measure-Object | Select -ExpandProperty Count) tables in the subreport report"
    foreach ($table in $subReport.Database.Tables){
        $table.ApplyLogOnInfo($tableLogOnInfo)
    }
}

Write-Output $report

}Export-ModuleMember -Function Change-CRDataSourceConnection