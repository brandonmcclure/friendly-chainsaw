function Get-SQLServerDataTypeFromDataTable {
  param([System.Data.DataTable]$table
    ,[string]$columnName)

  $outObj = New-Object PSObject
  $outObj | Add-Member -Type NoteProperty -Name "minValue" -Value 0
  $outObj | Add-Member -Type NoteProperty -Name "maxValue" -Value 0
  $outObj | Add-Member -Type NoteProperty -Name "derivedDataType" -Value 0
  $outObj | Add-Member -Type NoteProperty -Name "derivedSize" -Value 0
  $outObj | Add-Member -Type NoteProperty -Name "derivedFSDataTypeDefinition" -Value 0

  $col =  $table.Columns[$columnName]

  switch ($col.DataType.Name)
  {
    "DateTime" {
      $dataType = '[DateTime]'
      $outObj.derivedDataType = 'DateTime'
      $outObj.derivedFSDataTypeDefinition = $outObj.derivedDataType
      break
    }

    "String" {
      foreach ($dr in $table.Rows)
      {
        $curRowVal = $dr.Item($columnName)
        $outObj.MinValue = [math]::Min($outObj.MaxValue,$curRowVal.Length);
        $outObj.MaxValue = [math]::Max($outObj.MaxValue,$curRowVal.Length + 1);
      }
      $roundIn = $outObj.MaxValue / 10.0
      $roundOut = [math]::Ceiling($roundIn)
      $outObj.derivedSize = if ($outObj.MaxValue -ge 2147483647) { 'MAX' } else { $roundOut * 20 }
      $outObj.derivedDataType = 'VARCHAR'
      $outObj.derivedFSDataTypeDefinition = "VARCHAR($($outObj.derivedSize))"
      break

    }
    default {
      Write-Log "Defaulting to varchar(max) datatype" Debug
      $outObj.derivedSize = 'MAX'
      $outObj.derivedDataType = 'VARCHAR'
      $outObj.derivedFSDataTypeDefinition = "$($outObj.derivedDataType)($($outObj.derivedSize))"
      break
    }
  }




  Write-Output $outObj
} Export-ModuleMember -Function Get-SQLServerDataTypeFromDataTable
