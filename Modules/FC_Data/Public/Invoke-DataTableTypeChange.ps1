function Invoke-DataTableTypeChange{
    param ([Data.datatable]$dt, $desiredColumnTypes = @())
    $dtCloned = $dt.Clone()

    foreach($colType in $desiredColumnTypes){
        $t = [System.Type]::GetType($colType.datatype) 
        Write-Log "Casting column $($colType.name) as $(if(-not $Null -eq $t){$t.ToString()})"
        $dtCloned.Columns[$dt.Columns.IndexOf($colType.name)].DataType = $t

    }

foreach ($row in $dt.Rows) 
{
    $dtCloned.ImportRow($row);
}
Write-Output @(,($dtCloned))
} Export-ModuleMember -Function Invoke-DataTableTypeChange