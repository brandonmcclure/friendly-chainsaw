function Start-MySQLQueryJob {
<#
    .Synopsis
      Runs a SQL statement as a Powershell Background Job. The main benefit of doing it this way is that you can pass custom credentials while using integrated security for the SQL server
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    #>
  param([string]$JobSuffix
    ,[string]$sqlServer
    ,[string]$sqlDatabase = $null
    ,[string]$sqlQuery = $null
    ,[pscredential]$jobCreds = $null)

  if ([string]::IsNullOrEmpty($sqlQuery)) {
    Write-Log "Please pass a query using the sqlQuery parameter" Error -ErrorAction Stop
  }
  if ([string]::IsNullOrEmpty($JobSuffix)) {
    $JobSuffix = Get-StringHash $sqlQuery -hashAlgo SHA1
  }
  Write-Log "sqlServer: $sqlServer" Debug
  Write-Log "sqlDatabase: $sqlDatabase" Debug
  Write-Log "sqlQuery: $sqlQuery" Debug

  $running = Get-MyJobs -State 'Running'
  if ($running.count -le $Script:MaxJobs) {
    Write-Log "[Start-MySQLQueryJob] Starting job named $Script:JobPrefix$JobSuffix" Debug
    #If credentials are specified create the Invoke-SQLcmd job with them
    if ($jobCreds -eq $null) {
      Start-Job -ScriptBlock {
        param($jobQuery,$sqlServer,$sqlDatabase)
        $results = Invoke-Sqlcmd -Query $jobQuery -ServerInstance $sqlServer -Database $sqlDatabase
        $results
      } -ArgumentList ($sqlQuery,$sqlServer,$sqlDatabase) -Name "$Script:JobPrefix$JobSuffix"
    }
    else {
      Start-Job -ScriptBlock {
        param($jobQuery,$sqlServer,$sqlDatabase)
        $results = Invoke-Sqlcmd -Query $jobQuery -ServerInstance $sqlServer -Database $sqlDatabase
        $results
      } -ArgumentList ($sqlQuery,$sqlServer,$sqlDatabase) -Name "FC_$JobSuffix" -Credential $jobCreds
    }
    $true
  }
  else {
    $false
  }
} Export-ModuleMember -Function Start-MySQLQueryJob