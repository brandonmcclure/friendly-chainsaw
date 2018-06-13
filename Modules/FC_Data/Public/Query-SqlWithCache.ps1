function Query-SqlWithCache{
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
        Store a copy of the data locally to speed up any other queries. 
        The local cache will be located: C:\temp\$serverName$DatabaseName_$queryHash
        ie: (ServerDatabase_145868016216295781216920420294223571441041221777622495882505022372121155874110212)

        the function will use this cache object until it is older than 1 day. 
         
    .INPUTS
       A sql command
    .OUTPUTS
       A array of System.Data.DataRow. 
       The DataRow objects will have Properties that corespond to the columns returned by your data set.  
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Warning",[string] $ServerInstance
,[string] $Database
,[Parameter(position=1,ValueFromPipeline)][string] $query = $null
,[string] $cacheDir = "$env:Temp\Friendly_Chainsaw"
,[int] $cacheDays = 0
,[int] $QueryTimeout = 0
,[int] $ConnectionTimeout = 0
)
$currentLogLevel = Get-LogLevel
if (!([string]::IsNullOrEmpty($logLevel))){
        Set-LogLevel $logLevel
    }
    
Write-Log "ServerName : $ServerInstance" Debug
Write-Log "Database: $Database" Debug

$queryStartTime = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module BrandonLib
$queryHash = Get-StringHash $query
$fqPath = "$cacheDir$ServerInstance$($Database)_$queryHash.xml"
if (!(Test-Path  $fqPath)){
    Write-Log "Data is not cached, loading cache. File path: $fqPath" Debug
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeout
    $results | Export-Clixml -Path $fqPath
}
elseif( $(Get-ChildItem $fqPath).LastWriteTime -le (Get-Date).AddDays($cacheDays)){
    Write-Log "Refreashing local cache. File path: $fqPath" Debug
    Remove-item $fqPath
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query -QueryTimeout $QueryTimeout -ConnectionTimeout $ConnectionTimeout
    $results | Export-Clixml -Path $fqPath
}
else{
    Write-Log "Using local cache. File path: $fqPath" Debug
    $results = Import-Clixml $fqPath
}
$elapsedTime = $queryStartTime.ElapsedMilliseconds
Write-Log "Query took: $elapsedTime miliseconds" Debug
Set-LogLevel $currentLogLevel
$results

}Export-ModuleMember -function Query-SqlWithCache