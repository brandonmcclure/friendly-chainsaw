function New-SQLImportValuesStatementFromDataTable {
param([Parameter(Position = 0,ValueFromPipeline)] [System.Data.DataTable]$dataTable
    ,[Parameter(Position = 1)] [string]$FQTableName
    ,$ColumnMetaData
  )
  $SQLCreateTable = ""
  $colNames = $dataTable.Columns | sort -Property Ordinal
  $SQLInsert += "
INSERT INTO $FQTableName ("

  $firstPass = 1
  foreach ($col in $colNames) {

    
    Write-Log "Identifying the data type to use based on the dataTable you passed in" Debug

    $dataType = Get-SQLServerDataTypeFromDataTable -table $dataTable -columnName $col.ColumnName
    if ($firstPass -eq 1) {
      $SQLInsert += "[$(($col.ColumnName).Trim())]"
      $firstPass = 0
    }
    else {
      $SQLInsert += ",[$(($col.ColumnName).Trim())]"
    }
  }
  $SQLInsert = $SQLInsert + ")`n"

  $sqlValues ="Values`n"
  $rowfirstPass = 1
foreach($row in $dataTable.Rows)
{
    if ($rowfirstPass -eq 1) {
    $sqlValues += "("
    $rowfirstPass = 0
    }
    else{
        $sqlValues += ",("
    }
      $firstPass = 1
    foreach ($col in $dataTable.Columns){
        $quoteValue = $true
        if(($ColumnMetaData | where ColumnName -eq $col.ColumnName | measure-object | select -ExpandProperty count) -ne 0 ){
            $quoteValue = ($ColumnMetaData | where ColumnName -eq $col.ColumnName).QuoteValue
        }
        $dataType = Get-SQLServerDataTypeFromDataTable -table $dataTable -columnName $col.ColumnName
        $value = $($row[$col.ColumnName])
        if ($value -eq ''){$value = "NULL"}
        else{
            if($quoteValue){
            $value = "'$($value.Replace("'","''"))'"
            }
            else{
                $value = "$($value.Replace("'","''"))"
            }
        }

        if ($firstPass -eq 1) {
            $sqlValues+= "$value"
            $firstPass = 0
        }
        else{
                $sqlValues += ",$value"
            }
    }
    $sqlValues += ")`n"
    
} 


  Write-Log "$SQLInsert$sqlValues" Debug
  Write-Output "$SQLInsert$sqlValues"
}Export-ModuleMember -Function New-SQLImportValuesStatementFromDataTable