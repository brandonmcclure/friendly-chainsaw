$script:logLevelOptions = @{"Debug" = 0; "Info" = 10; "Warning" = 20; "Error" = 30; "Disable" = 100} 
$script:LogSource = "FC Powershell Scripts"
$script:logTargetFileDir = "logs\$($env:computername)\$(Get-Date -f yyyy-MM-dd)\"
$script:logTargetFileName = $null
$script:logLevel = 10
$script:logTargetConsole = 1
$script:logTargetFile = 0
$script:logTargetWinEvent = 0

function Set-logTargetWinEvent{
    <#
    .Synopsis
      Configures the logger to write events to the Windows event log. 
    .DESCRIPTION
      This function is used to set a script scoped variable that toggles weather the logger writes the message to the windows event log. Useful for debugging scripts running on remote machines. 
    .PARAMETER onoff
        Simple boolean that controls the write to event log flag. true/false, 1/0 
        defaults to false
       
    .EXAMPLE
        Set-logTargetWinEvent $true
    #>
	Param([Parameter(Position=0)][bool] $onoff)
	if ($onoff){
		$script:logTargetWinEvent = 1
	}
	else{
		$script:logTargetWinEvent = 0
	}
}export-modulemember -Function Set-logTargetWinEvent
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

        Import-Module Logger

        Set-LogLevel $logLevel
    #>
	Param([Parameter(Position=0)][ValidateScript({		 
		 $script:logLevelOptions.ContainsKey($_)
		})]
		[string] $level)
		
	Try{
        if (!([string]::IsNullOrEmpty($level))){
		    $script:LogLevel = $script:logLevelOptions[$level]
        }
	}
	Catch{
		Write-Log "Error setting the log level." 
	}

}export-modulemember -function Set-LogLevel
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
function Set-logTargetFileDir{
<#
    .Synopsis
      Set the direcotry the log file will be created in if you turn on the write to file for the logger
    .PARAMETER directory
        The path to the directory you want the log to be created in. Will try to create the directory if it does not exist.    
    .EXAMPLE
        Set-logTargetFileDir "C:\temp"
    #>
   Param([Parameter(Position=0)]$directory)
   $script:logTargetFileDir = "$($MyInvocation.PSScriptRoot)\$directory"
    if (!(Test-Path $script:logTargetFileDir)){
            Write-Log "$script:logTargetFileDir does not exist. Creating it"
            mkdir $script:logTargetFileDir
        }
}export-modulemember -Function Set-LogTargetFileDir
function Get-logTargetFileDir{
<#
    .Synopsis
      returns the direcotry the log files will be created in.
    #>
    $script:logTargetFileDir
}export-modulemember -Function Get-logTargetFileDir
function Write-Log{
<#
    .Synopsis
       Writes a message to one of several streams. The default "info" messages use Write-Host, 
	.Description
        Write-Log is the central function for the logger module. It is designed to wrap the several ways to log data into one easy to use function. Using Write-Log in your script, you can then decide at run time if you want your messages to display or not, and to what stream you want them written. A common use is to Set-logLevel to Error when the scripts are running in production, and then if an error occurs reruning the scripts with Debug level, and possible write to the Windows event log to help you in troubleshooting. 
        
		NOTE: When you use -ErrorAction Stop on this function it will not write any errors in the calling scope
	.PARAMETER Message
		The $Message parameter is the text that will be written. Position=0
	.PARAMETER EventLevel
		Specifies the entry type of the event. Position=1 
		Valid values are "Debug","Info","Warning","Error"

        The default level of Info is used if not specified. Write-Log checks against the script scoped logLevel, if the Write-Log spe
	.PARAMETER eventID
		Only used when you Set-logTargetWinEvent on. The Event ID for the windows event log. Can be any number between 0 and 65535, defaults to 10. Position=3
     .EXAMPLE
        Writes a message as a Information event level. Good for general logging to the screen. If the Verbose preference variable was set to 'Continue' this message would be written to the Verbose stream, if not it is written to host. 
       Write-Log "Basic information message"

       
	.EXAMPLE
        Writing a error message to the Windows Event Log a message as a Error event level, with the max eventID value of 65535. This will call Write-Error to raise an error on the PowerShell host, and write the log to the Windows Event log with the event ID: 65535

        Set-logTargetWinEvent $true

       Write-Log "Testing out a error message" Error -eventID 65535
    .INPUTS
        Accepts a string value for the message that will be written
    #>
	[CmdletBinding()]
	param( 
		[Parameter(ValueFromPipeline=$True, Position=0)] [string] $Message = "", 
		[Parameter(Position=1)][ValidateSet("Debug", "Info" , "Warning" , "Error", "Disable")][string] $EventLevel = "Info", 
		[Parameter(Position=3)][int] $eventID = 10
		)
        
		if ($script:LogLevel -eq 100){
			return
		}
		$messageLevel = $script:logLevelOptions[$EventLevel]
	    #Set the Verbose preference to the value in the calling script
	    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
	
	#Debug Messages
	if ($messageLevel -eq 0 -and $script:LogLevel -eq 0){
		$FormatMessage = "[DEBUG] $Message"
        if ($DebugPreference -eq "Inquire" -or $DebugPreference -eq "Continue"){
            Write-Debug "$Message"
        }
        else{
		    Write-Host "$FormatMessage" -ForegroundColor Cyan
        }
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
			}
        if ($script:logTargetFile -eq 1){
            
            Add-Content -Value $FormatMessage -Path "$script:logTargetFileDir\$script:logTargetFileName"
        }
	}
	#Info Messages
	elseif($messageLevel -eq 10 -and $script:LogLevel -le 10){
		$FormatMessage = "$Message"
        if ($VerbosePreference -eq 'Continue'){
		    Write-Verbose "$FormatMessage"
        }
        else{
            Write-Host "$FormatMessage" -ForegroundColor Green
        }
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
			}
        if ($script:logTargetFile -eq 1){ 
            Add-Content -Value $FormatMessage -Path "$script:logTargetFileDir\$script:logTargetFileName"
        }
	}
	#Warning Messages
	elseif ($messageLevel -eq 20 -and $script:LogLevel -le 20){
		$FormatMessage = "[WARNING] $Message"
		Write-Warning "$Message"
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Warning" -EventId $eventID -Message "$FormatMessage"
			}
        if ($script:logTargetFile -eq 1){
            Add-Content -Value $FormatMessage -Path "$script:logTargetFileDir\$script:logTargetFileName"
        }
	}
	#Error Messages
	elseif ($messageLevel -eq 30 -and $script:LogLevel -le 30){
		$FormatMessage = "$Message"
		Write-Error "$FormatMessage"
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Error" -EventId $eventID -Message "$FormatMessage"
			}
        if ($script:logTargetFile -eq 1){
            Add-Content -Value $FormatMessage -Path "$script:logTargetFileDir\$script:logTargetFileName"
        }
	}
}export-modulemember -function Write-Log