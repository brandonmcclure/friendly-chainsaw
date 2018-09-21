Function New-SQLTableStatementFromDataTable{
<#
    .Synopsis
      Creates a MS SQL Server create table statement based on the DataTable that is passed in. It makes very limited assumptions on the data type for each column.
    .DESCRIPTION
      This function is used when we recieve our .rpt files from a vendor. The files all use ODBC conenctions to a single database, but they are pointed to the vendor's development database. Using Get-ChildITem | Open-CrystalReport | Change-CRDataSourceConnection |  Close-CrystalReport we can quickly update all the files we recieve so our developers do not need to manually update the connections for each report file. 
       
    .EXAMPLE
        Opens all .rpt files in C:\reportsFromVendor and all subdirectories and updates the connections to use the ODBC DSN 'devODBCConnection' and the database "DevelopmentDatabase"

        Get-ChildItem C:\reportsFromVendor -recurse | where {$_.Extension -eq 'rpt'} | Open-CrystalReport | Change-CRDataSourceConnection -ODBCdsnName "devODBCConnection" -databaseName "DevelopmentDatabase" |  Close-CrystalReport
    .PARAMETER dataTable
        Default: $Null
        Required
        Type: [System.Data.DataTable]
        
        The data table that you want to generate the create table statement for. 
    .PARAMETER FQTableName
        Default: $null
        Required
        Type: [String]

        The fully qualified name of the new table. Should include the schema and the table name.
     .EXAMPLE
        Queries a SQL server and returns a DataTable. Generate a Create table statement from the datatable you got from the $destDatabase.

        $sqlQuery = 'Select [DateTimeColumn], [varchar100Column], [VarcharMAXColumn] from mySchema.myTable'
        $dataAsDataTable = Invoke-SQLCmd_DataTable -ServerInstance $sourceServer -Database $sourceDatabase -Query $sqlQuery

        $createTableScript = New-SQLTableStatementFromDataTable -dataTable $dataAsDataTable -FQTableName "myNewSchema.myNewTable"

        $createTableScript will contain:

        Create Table myNewSchema.myNewTable(
            DateTimeColumn DateTime Null,
            varchar100Column Varchar(100) null,
            VarcharMAXColumn Varchar(max) null
        );
         
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0,ValueFromPipeline)][System.Data.DataTable] $dataTable
,[Parameter(position=1)][string] $FQTableName
)
$SQLCreateTable = ""
$colNames = $dataTable.Columns | sort -Property Ordinal  
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