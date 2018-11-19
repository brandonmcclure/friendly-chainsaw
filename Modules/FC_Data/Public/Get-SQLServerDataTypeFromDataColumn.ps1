Function Get-SQLServerDataTypeFromDataColumn{
param([System.Data.DataColumn] $col)
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

    Write-Output $dataType
    }Export-ModuleMember -Function Get-SQLServerDataTypeFromDataColumn