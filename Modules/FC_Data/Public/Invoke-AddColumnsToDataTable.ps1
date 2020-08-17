Function Invoke-AddCOlumnsToDataTable{
param([System.Data.DataTable]$datatable,
[hashtable]$Columns_ToAdd
)
$preAddColumns = @()
    foreach ($column in $Columns_ToAdd.GetEnumerator()){
        Write-Log "Adding column: $($column.Name)" -tabLevel 1
        $datatable.Columns.Add($column.Name,(Get-Type $column.Value)) | Out-Null
    }
    #Add columns and order
    Write-Output @(,($datatable))
}Export-ModuleMember -function Invoke-AddCOlumnsToDataTable