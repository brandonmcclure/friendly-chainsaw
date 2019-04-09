function Invoke-SqlCmdWithCache {
<#
    .Synopsis
        Wrapper for Invoke-SQLCmd cmdlt which has some error handling, server name resolution, and optional local caching. 
    .PARAMETER query
        The sql query to execute
     .PARAMETER CacheResultsLocally
        A switch that when specified will locally cache data to speed up subsequent queries
    .PARAMETER cacheDir
        A directory that the xml files that store the cached data will be stored in. Default is C:\temp
        YOU NEED TO CLEAN THESE FILES UP YOUR SELF!!!
    .PARAMETER cacheDays
        A integer that specifies how old a file can be before the local cache is refreashed. Default is -1 (1 day old) 

        Set this to a positive number to force a refreash of the local cache. 

     .EXAMPLE
        
        Store a copy of the data locally to speed up any other queries until the cached data is 5 days old.

        The local cache will use the default $cacheDir: C:\temp\Friendly_Chainsaw\$sourceServer$sourceDatabase_$queryHash
        ie: (ServerDatabase_145868016216295781216920420294223571441041221777622495882505022372121155874110212)
        
        $sqlQuery = 'Select [DateTimeColumn], [varchar100Column], [VarcharMAXColumn] from mySchema.myTable'
        $dataAsDataTable = Query-SqlWithCache -ServerInstance $sourceServer -Database $sourceDatabase -Query $sqlQuery -cacheDays -5
         
    .INPUTS
       A sql command
    .OUTPUTS
       An array of powershell objects  
    #>
  [CmdletBinding(SupportsShouldProcess = $true)]
  param([Parameter(Position = 0)][ValidateSet("Debug","Info","Warning","Error","Disable")] [string]$logLevel = "Warning",[string]$ServerInstance
    ,[string]$Database
    ,[Parameter(Position = 1,ValueFromPipeline)] [string]$query = $null
    ,[string]$cacheDir = "$env:Temp\Friendly_Chainsaw"
    ,[int]$cacheDays = -1
  )
  $currentLogLevel = Get-LogLevel
  if (!([string]::IsNullOrEmpty($logLevel))) {
    Set-LogLevel $logLevel
  }

  Write-Log "ServerName : $ServerInstance" Debug
  Write-Log "Database: $Database" Debug

  $queryStartTime = [System.Diagnostics.Stopwatch]::StartNew()
  $queryHash = Get-StringHash $query
  $fqPath = "$cacheDir$ServerInstance$($Database)_$queryHash.xml"
  if (!(Test-Path $fqPath)) {
    Write-Log "Data is not cached, loading cache. File path: $fqPath" Debug
    Write-Log "sql cmd: $query" Debug
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query -QueryTimeout 0 -ConnectionTimeout 0
    $results | Export-Clixml -Path $fqPath
  }
  elseif ($(Get-ChildItem $fqPath).LastWriteTime -le (Get-Date).AddDays($cacheDays)) {
    Write-Log "Refreashing local cache. File path: $fqPath" Debug
    Write-Log "sql cmd: $query" Debug
    Remove-Item $fqPath
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query -QueryTimeout 0 -ConnectionTimeout 0
    $results | Export-Clixml -Path $fqPath
  }
  else {
    Write-Log "Using local cache. File path: $fqPath" Debug
    $results = Import-Clixml $fqPath
  }
  $elapsedTime = $queryStartTime.ElapsedMilliseconds
  Write-Log "Query took: $elapsedTime miliseconds" Debug
  Set-LogLevel $currentLogLevel
  Write-Output $results

} Export-ModuleMember -Function Invoke-SqlCmdWithCache
