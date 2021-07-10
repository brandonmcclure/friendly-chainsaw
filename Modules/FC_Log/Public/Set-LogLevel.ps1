function Set-LogLevel {
<#
    .Synopsis
      Sets the configured log level. This controls which level of messages are written.  
    .DESCRIPTION
       Valid options are: "Debug","Info","Warning","Error","Disable"
       Debug is the most verbose, as all the other messages will display. If the logLevel is Disable then no messages will be written.

       When the logLev is set to Debug and the -Debug advanced parameter is set for the caller, the Write-Log messages with a Debug level will cause the Powershell debuger to take over. 
    .PARAMETER level
        Valid options are: "Debug","Info","Warning","Error","Disable"
       
    .EXAMPLE
        Setting the log level in a script, allowing the Logger to default to "Info" if nothing is passed to the script.
        param([string] $logLevel = $null)

        Import-Module FC_Log

        if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Warning"}
        Set-LogLevel $logLevel
    #>
Param([Parameter(Position=0, ParameterSetName="string")][ValidateScript({		 
		 $script:logLevelOptions.ContainsKey($_)
		})]
		[string] $levelStr,
        [Parameter(Position=0, ParameterSetName="int")][ValidateScript({		 
		 $script:logLevelOptions.ContainsValue($_)
		})]
		[int] $levelInt)
		
	Try{
        if (!([string]::IsNullOrEmpty($levelStr))){
		    $script:LogLevel = $script:logLevelOptions[$levelStr]
        }
        else
        {
            $script:LogLevel = $levelInt
        }
	}
	Catch{
		Write-Log "Error setting the log level." 
	}

}