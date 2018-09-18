Function Change-CRDataSourceConnection{
<#
    .Synopsis
      Updates the data source of all tables in the report and all sub reports to use the specified ODBC DSN and database. 

      *NOTE* This function does not check the connection type and has not been tested on reports that do not use ODBC connections, or connections to multiple databases. Use at your own risk! 
    .DESCRIPTION
      This function is used when we recieve our .rpt files from a vendor. The files all use ODBC conenctions to a single database, but they are pointed to the vendor's development database. Using Get-ChildITem | Open-CrystalReport | Change-CRDataSourceConnection |  Close-CrystalReport we can quickly update all the files we recieve so our developers do not need to manually update the connections for each report file. 
       
    .EXAMPLE
        Opens all .rpt files in C:\reportsFromVendor and all subdirectories and updates the connections to use the ODBC DSN 'devODBCConnection' and the database "DevelopmentDatabase"

        Get-ChildItem C:\reportsFromVendor -recurse | where {$_.Extension -eq 'rpt'} | Open-CrystalReport | Change-CRDataSourceConnection -ODBCdsnName "devODBCConnection" -databaseName "DevelopmentDatabase" |  Close-CrystalReport

    .INPUTS
       A CrystalDecisions.CrystalReports.Engine.ReportDocument object
       A DSN name for an ODBC connection. This does not check if the DSN is registered on the machine or is valid in any way. 
       A database name 
    .OUTPUTS
       A CrystalDecisions.CrystalReports.Engine.ReportDocument object
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(ValueFromPipeline,position=0)] $report
,[string] $ODBCdsnName = $null
,[string] $databaseName = $null
)
Load-CrystalDecisionAssemblies

if ([string]::IsNullOrEmpty($ODBCdsnName)){
    Write-Log "Please pass a value to the ODBCdsnName parameter" -ErrorAction Stop
}
if([string]::IsNullOrEmpty($databaseName)){
    Write-Log "Please pass a value to the databaseName parameter" -ErrorAction Stop
}
if ($report -eq $null){
    Write-Log "Invalid input object. Please pass a Crystal Report object from the Open-CrystalReport function." Error -ErrorAction Stop
}
$connectionInfo = $report.Database.Tables[0].LogOnInfo.ConnectionInfo;
$connectionInfo.ServerName = $ODBCdsnName
$connectionInfo.DatabaseName = $databaseName
$connectionInfo.IntegratedSecurity = $false

$tableLogOnInfo = New-Object CrystalDecisions.Shared.TableLogOnInfo 
$tableLogOnInfo.ConnectionInfo = $connectionInfo

Write-Log "Setting the connection at the report level"
$report.DataSourceConnections[0].SetConnection($ODBCdsnName, $databaseName, $true)

Write-Log "There are $($report.Database.Tables | Measure-Object | Select -ExpandProperty Count) tables in the base report"
foreach ($table in $report.Database.Tables){
 
    Write-Log "Setting the connection for the $($table.Name) table"
    $table.ApplyLogOnInfo($tableLogOnInfo)

}

Write-Log "There are $($report.Subreports | Measure-Object | Select -ExpandProperty Count) subreports in the base report"
foreach ($subReport in $report.Subreports){
    Write-Log "Setting the connections for the $($subReport.Name) subreport"
    Write-Log "There are $($subReport.Database.Tables | Measure-Object | Select -ExpandProperty Count) tables in the subreport report"
    foreach ($table in $subReport.Database.Tables){
        Write-Log "Setting the connection for the $($table.Name) table" -tabLevel 1
        $table.ApplyLogOnInfo($tableLogOnInfo)
    }
}

Write-Output $report

}Export-ModuleMember -Function Change-CRDataSourceConnection