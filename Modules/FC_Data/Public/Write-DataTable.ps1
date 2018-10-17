function Write-DataTable {
<# 
.SYNOPSIS 
    Writes data from a DataTable into SQL Server tables. Only works with MS SQL Server.
.DESCRIPTION 
    Writes data only to SQL Server tables. However, the data source is not limited to SQL Server; any data source can be used, as long as the data can be loaded to a DataTable instance or read with a IDataReader instance. 
.INPUTS 
    A DataTable
.OUTPUTS 
None 
    Produces no output 
.EXAMPLE 
    $dt = Invoke-Sqlcmd2 -ServerInstance "Z003\R2" -Database pubs "select *  from authors" 
    Write-DataTable -ServerInstance "Z003\R2" -Database pubscopy -TableName authors -Data $dt 
    This example loads a variable dt of type DataTable from query and write the datatable to another database 
.PARAMETER BatchSize
    Default: 5000 
    Optional

    If set to a value greater than 0, will set the BatchSize of the BulkCopy object. If set to 0 (or less) then it will default to the unlimited batch size, which may cause memory issues on your machine depending on your data and your computer. 
.NOTES 
    Write-DataTable uses the SqlBulkCopy class see links for additional information on this class. 
    Version History 
    v1.0   - Chad Miller - Initial release 
    v1.1   - Chad Miller - Fixed error message 
    V2.0   - Brandon McClure - Refactor to use PSCredential instead of plaintext username and passwords.
    v2.1   - Brandon McClure - If batch size is not passed, use the default (unlimited) batch size for the bulk copy  
.LINK 
    http://msdn.microsoft.com/en-us/library/30c3y597%28v=VS.90%29.aspx 
    https://gallery.technet.microsoft.com/ScriptCenter/2fdeaf8d-b164-411c-9483-99413d6053ae/
#>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory = $true)] [string]$ServerInstance,
    [Parameter(Position = 1,Mandatory = $true)] [string]$Database,
    [Parameter(Position = 2,Mandatory = $true)] [string]$TableName,
    [Parameter(Position = 3,Mandatory = $true,ValueFromPipeline)] [System.Data.DataTable]$Data,
    [Parameter(Position = 4,Mandatory = $false)] [pscredential]$databaseCredentials,
    [Parameter(Position = 5,Mandatory = $false)] [int32]$BatchSize = 5000,
    [Parameter(Position = 6,Mandatory = $false)] [int32]$QueryTimeout = 0,
    [Parameter(Position = 7,Mandatory = $false)] [int32]$ConnectionTimeout = 15
  )

  $conn = New-Object System.Data.SqlClient.SQLConnection

  if ($databaseCredentials)
  { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$databaseCredentials.UserName,$databaseCredentials.Password,$ConnectionTimeout }
  else
  { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout }

  $conn.ConnectionString = $ConnectionString

  try
  {
    $conn.Open()
    $bulkCopy = New-Object ("Data.SqlClient.SqlBulkCopy") $connectionString
    $bulkCopy.DestinationTableName = $tableName
    if ($BatchSize -gt 0) {
      $bulkCopy.BatchSize = $BatchSize
    }
    $bulkCopy.BulkCopyTimeout = $QueryTimeOut
    $bulkCopy.WriteToServer($Data)
    $conn.Close()
  }
  catch
  {
    $ex = $_.Exception
    Write-Error "$ex.Message"
    continue
  }

} Export-ModuleMember -Function Write-DataTable
