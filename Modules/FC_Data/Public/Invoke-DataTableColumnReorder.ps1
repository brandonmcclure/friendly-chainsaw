function Invoke-DataTableColumnReorder {
<# 
.SYNOPSIS 
    Takes a DataTable, and reorders and removes columns based on an array of column names you pass in
.DESCRIPTION
    I wrote this function while building a process to load many CSV and TXT files that were produced by a third party vendor into our staging database. Not all files would be loaded regularly, but we needed to get them loaded quickly to identify which files were needed and which were not. There are times that the files are not consistant between runs, which was where this specific function came into play. 
.INPUTS 
     DataTable - A System.Data.DataTable that we will be acting on. Can be passed in by pipeline

.OUTPUTS 
   System.Data.DataTable 
.PARAMETER
    DataTable

.PARAMETER
    columnOrder
        An string array of column names in the order that you would like the DataTable columns to be in.
.EXAMPLE 

Takes a csv file with headers located at $inputFilePath and injects 2 columns to the front of the DataTable to stamp the row with a DateTime of when it was loaded, and what parent folder the file was in. This is done prior to loading the DataTable into SQL Server 

     $ColumnNames_FileOrder = (Get-Content $inputFilePath | select-Object -first 1).Split(",")

    $data = Import-Csv $inputFilePath
    $data | Add-Member -MemberType NoteProperty -Name rowLoadedDTTM -Value $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $data | Add-Member -MemberType NoteProperty -Name fileParentFolder -Value $parentFolderName
        
    $dataAsDataTable = $data | Out-DataTable

    #$columnIndex = 0
    $ColumnNames_DesiredOrder = @()
    $ColumnNames_DesiredOrder += "rowLoadedDTTM"
    $ColumnNames_DesiredOrder += "fileParentFolder"
    $ColumnNames_DesiredOrder += $ColumnNames_FileOrder

    $dataAsDataTable = Invoke-DataTableColumnReorder -DataTable $dataAsDataTable -columnOrder $ColumnNames_DesiredOrder 

.EXAMPLE

Building upon the previous example, this one takes the previous data table with data from a CSV file and values determined at run time and loads it into a table in SQL server. It is possible that table in SQL Server does not have columns that exist in our data table. This example uses Invoke-DataTableColumnReorder to ensure that the local DataTable and the SQL table have consistent column mappings by reordering columns that exist in both, and removing columns that do not exist on the SQL server.
$destServerName and $destDatabase are set at script run time. 
$schemaName and $tableName are set dynamically based on the files that will be loaded. 

    Write-Log "Checking if the column order of my datatable matches the ordering on the SQL server" Debug
    $ColumnNames_SqlServer = (Invoke-Sqlcmd -ServerInstance $destServerName -Database $destDatabase -Query  "select Column_name from INFORMATION_SCHEMA.COLUMNS col where col.TABLE_CATALOG = '$destDatabase' and col.TABLE_SCHEMA = '$schemaName' and col.TABLE_NAME = '$tableName' order by ORDINAL_POSITION").Column_name
    $columnIndex = 0
    $columnsToRemoveIndex =0
    foreach ($column in $ColumnNames_DesiredOrder){
        if ($column -ne $ColumnNames_SqlServer[$columnIndex - $columnsToRemoveIndex]){
            $ColumnNames_DesiredOrder = $ColumnNames_DesiredOrder | where {$_ -ne $column}
            $columnsToRemoveIndex += 1
        }
        $columnIndex += 1
    }
    $dataAsDataTable = Invoke-DataTableColumnReorder -DataTable $dataAsDataTable -columnOrder $ColumnNames_DesiredOrder
    Write-Log "Loading data into $FQTableName" -tabLevel 1
    Write-DataTable -serverInstance $destServerName -Database $destDatabase -TableName $FQTableName -data $dataAsDataTable -ErrorAction Stop 
#>
  [OutputType([Data.datatable])]
  param([Parameter(Position = 0,Mandatory = $true,ValueFromPipeline = $true)] [Data.datatable]$DataTable,[string[]]$columnOrder)
  $columnIndex = 0
  foreach ($column in $columnOrder) {
    if ($DataTable.Columns.Contains($column)) {
      $DataTable.Columns[$column].SetOrdinal($columnIndex)
      $columnIndex++
    }
    else {
      Write-Log "Column named: $column does not exist" Warning
    }


  }
  Write-Log "Removing other columns from the data table" Debug
  $removeColumnIndex = $DataTable.Columns.count
  for ($removeColumnIndex = $DataTable.Columns.count - 1; $removeColumnIndex -ge $columnIndex; $removeColumnIndex --) {
    Write-Log "Removing column: $($DataTable.Columns[$removeColumnIndex])" Warning
    $DataTable.Columns.RemoveAt($removeColumnIndex)
  }
  Write-Output @(,($DataTable))
} Export-ModuleMember -Function Invoke-DataTableColumnReorder