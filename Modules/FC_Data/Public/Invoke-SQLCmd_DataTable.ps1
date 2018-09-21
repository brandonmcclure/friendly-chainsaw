function Invoke-SQLCmd_DataTable{
[CmdletBinding(SupportsShouldProcess=$true)] 
param($ServerInstance, $Database, $Query, [int] $QueryTimeout, [int] $ConnectionTimeout)

      $Datatable = New-Object System.Data.DataTable 
       
      $Connection = New-Object System.Data.SQLClient.SQLConnection 
      $Connection.ConnectionString = "server='$ServerInstance';database='$Database';trusted_connection=true;" 
      $Connection.Open() 
      $Command = New-Object System.Data.SQLClient.SQLCommand 
      $Command.Connection = $Connection 
      $Command.CommandText = $Query 
      $Reader = $Command.ExecuteReader() 
      $Datatable.Load($Reader) 
      $Connection.Close() 
      Write-Output @(,($Datatable)) 


}Export-ModuleMember -function Invoke-SQLCmd_DataTable