function New-AlterSQLTableStatementFromColumn {
  param([Parameter(Position = 0,ValueFromPipeline)] [System.Data.DataColumn]$dataColumn
    ,[Parameter(Position = 1)] [string]$FQTableName
  )
 

  "ALTER TABLE $FQTableName
 ADD [$($dataColumn.COlumnName)] [varchar](max) NULL;"

  $SQLCreateTable += "
Create table $FQTableName (`n"

  $firstPass = 1
  foreach ($col in $colNames) {
    Write-Log "Identifying the data type to use based on the dataTable you passed in" Debug
    switch ($col.DataType.Name)
    {
      "DateTime" {
        $dataType = '[DateTime]'
        break
      }
      "String" {
        $size = if ($col.MaxLength -eq -1 -or $col.MaxLength -eq 2147483647) { 'MAX' } else { $col.MaxLength }
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
    Write-Log "Generated SQL for $FQTableName" Debug
  Write-Log $SQLCreateTable Debug
  Write-Output $SQLCreateTable
} Export-ModuleMember -Function New-AlterSQLTableStatementFromColumn
