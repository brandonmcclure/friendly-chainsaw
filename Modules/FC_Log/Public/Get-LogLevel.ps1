function Get-LogLevel {
<#
    .Synopsis
      Gets the value of the logger configured logLevel   
       
    .EXAMPLE
        $configedLogLevel - Get-LogLevel
    #>
    foreach($key in $script:logLevelOptions.GetEnumerator() | WHere {$_.Value -eq $script:LogLevel}){
        $key.name
    }
}export-modulemember -Function Get-LogLevel