function Invoke-SqlAgentJobSync {
<#
    .Synopsis
      Executes a SQL server agent job
    #>
  param(
    [string]$instancename = $null,
    [string]$jobname = $null
  )

  $db = "MSDB"
  $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
  $sqlConnection.ConnectionString = 'server=' + $instancename + ';integrated security=TRUE;database=' + $db
  $sqlConnection.Open()
  $sqlCommand = New-Object System.Data.SqlClient.SqlCommand
  $sqlCommand.CommandTimeout = 120
  $sqlCommand.Connection = $sqlConnection
  $sqlQuery = "exec dbo.sp_start_job $jobname"
  Write-Log "sqlQuery: $sqlQuery" Debug
  $sqlCommand.CommandText = $sqlQuery
  Write-Host "Executing Job => $jobname..."
  $result = $sqlCommand.ExecuteNonQuery()
  $sqlConnection.Close()
} Export-ModuleMember -Function Invoke-SqlAgentJobSync