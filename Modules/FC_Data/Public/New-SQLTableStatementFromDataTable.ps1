Function New-SQLTableStatementFromDataTable{
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
,[System.Data.DataTable] $dataTable
,[string] $FQTableName
)
$SQLCreateTable = ""
$colNames = $dataTable.Columns | sort -Property Ordinal #| select ColumnName, DataType, AllowDBNull, AutoIncrement, 
$SQLCreateTable += "
Create table $FQTableName (`n"

      $firstPass = 1
      foreach ($col in $colNames) {
        Write-Log "Identifying the data type to use based on the dataTable you passed in" Debug
        switch ($col.DataType.Name)
            {
            "DateTime"{
                    $dataType = '[DateTime]'
                    break
                }
            "String"{
                $size = if ($col.MaxLength -eq -1 -or $col.MaxLength -eq 2147483647) {'MAX'}else{$col.MaxLength}
                $dataType = "varchar($size)"

            }
            default {
                    Write-Log "Defaulting to varchar(max) datatype" Debug
                    $dataType = 'varchar(max)'
                    break
                }
            }
        if ($firstPass -eq 1) {
          $SQLCreateTable = $SQLCreateTable + "[$($col.ColumnName)] $dataType null`n"
          $firstPass = 0
        }
        else {
          $SQLCreateTable = $SQLCreateTable + ",[$($col.ColumnName)] $dataType null`n"
        }
      }
      $SQLCreateTable = $SQLCreateTable + "`n);

    "
    Write-Log $SQLCreateTable Debug
Write-Output $SQLCreateTable
}Export-ModuleMember -Function New-SQLTableStatementFromDataTable