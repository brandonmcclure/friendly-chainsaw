$script:logLevelOptions = @{"Debug" = 0; "Info" = 10; "Warning" = 20; "Error" = 30; "Disable" = 100} 
$script:LogSource = "FC Powershell Scripts"
$script:logTargetFileDir = "logs\$($env:computername)\$(Get-Date -f yyyy-MM-dd)\"
$script:logTargetFileName = $null
$script:logLevel = 10
$script:logTargetConsole = 1
$script:logTargetFile = 0
$script:logTargetWinEvent = 0

$script:logFormattingOptions = @{"PrefixCallingFunction" = 0; "AutoTabCallsFromFunctions" = 0; "PrefixTimestamp" = 0} 

function Get-CallerPreference{
    <#
    .Synopsis
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]
        $Name
    )

    begin
    {
        $filterHash = @{}
    }
    
    process
    {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end
    {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }


        foreach ($entry in $vars.GetEnumerator())
        {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name)))
            {
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
                
                if ($null -ne $variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered')
        {
            foreach ($varName in $filterHash.Keys)
            {
                if (-not $vars.ContainsKey($varName))
                {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)
                
                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }

    } # end
} Export-ModuleMember -Function Get-CallerPreference
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
function Get-LogFormattingOptions{
    $script:logFormattingOptions
}export-modulemember -Function Get-LogFormattingOptions
function Set-LogFormattingOptions{
    param([int] $PrefixCallingFunction = -1,[int] $AutoTabCallsFromFunctions = -1,[int] $PrefixTimestamp = -1)

    if ($PrefixCallingFunction -eq 1 -or $PrefixCallingFunction -eq 0){
        $script:logFormattingOptions['PrefixCallingFunction'] = $PrefixCallingFunction
    }
    if ($AutoTabCallsFromFunctions -eq 1 -or $AutoTabCallsFromFunctions -eq 0){
        $script:logFormattingOptions['AutoTabCallsFromFunctions'] = $AutoTabCallsFromFunctions
    }
    if ($PrefixTimestamp -eq 1 -or $PrefixTimestamp -eq 0){
        $script:logFormattingOptions['PrefixTimestamp'] = $PrefixTimestamp
    }
}export-modulemember -Function Set-LogFormattingOptions
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
		[Parameter(Position=2)][int] $eventID = 10,
        [Parameter(Position=3)][int] $tabLevel = 0
		    
		)
        
		if ($script:LogLevel -eq 100){
			return
		}
		$messageLevel = $script:logLevelOptions[$EventLevel]
	    #Set the Verbose preference to the value in the calling script
	    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
   
        $tabs = ''
        if ($script:logFormattingOptions['AutoTabCallsFromFunctions'] -eq 1){
            $callingFunction = (Get-PSCallStack | Select-Object FunctionName -Skip 1 -First 1).FunctionName | where {$_ -ne '<ScriptBlock>'} 
            if (!([string]::IsNullOrEmpty($callingFunction))){
                $tabLevel ++
            }
        }
        for ($i=1;$i -le $tabLevel| where {$_ -ne 0}; $i++ ){
            $tabs = $tabs+'     '
        }

        $timeStamp = ''
        if ($script:logFormattingOptions['PrefixTimestamp'] -eq 1){
            $timeStamp = "$(Get-Date) - "
        }
              
        
	#Debug Messages
	if ($messageLevel -eq 0 -and $script:LogLevel -eq 0){
        if ($script:logFormattingOptions['PrefixCallingFunction'] = 1 -and !([string]::IsNullOrEmpty($callingFunction))){
            $FormatMessage = "$tabs$timeStamp[$callingFunction][DEBUG] $Message"
        }
        else{
		    $FormatMessage = "$tabs$timeStamp[DEBUG] $Message"
        }

        if ($DebugPreference -eq "Inquire" -or $DebugPreference -eq "Continue"){
            Write-Debug "$Message"
        }
        else{
		    Write-Host "$FormatMessage" -ForegroundColor Cyan
        }
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
			}
										 
			
																										
		 
	}
	#Info Messages
	elseif($messageLevel -eq 10 -and $script:LogLevel -le 10){
        if ($script:logFormattingOptions['PrefixCallingFunction'] = 1 -and !([string]::IsNullOrEmpty($callingFunction))){
            $FormatMessage = "$tabs$timeStamp[$callingFunction] $Message"
        }
        else{
		    $FormatMessage = "$tabs$timeStamp$Message"
        }
        if ($VerbosePreference -eq 'Continue'){
		    Write-Verbose "$FormatMessage"
        }
        else{
            Write-Host "$FormatMessage" -ForegroundColor Green
        }
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
			}
										  
																										
		 
	}
	#Warning Messages
	elseif ($messageLevel -eq 20 -and $script:LogLevel -le 20){
        if ($script:logFormattingOptions['PrefixCallingFunction'] = 1 -and !([string]::IsNullOrEmpty($callingFunction))){
            $FormatMessage = "$tabs$timeStamp[$callingFunction][WARNING] $Message"
        }
        else{
		    $FormatMessage = "$tabs$timeStamp[WARNING] $Message"
        }
		Write-Warning "$FormatMessage"
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Warning" -EventId $eventID -Message "$FormatMessage"
			}
										 
																										
		 
	}
	#Error Messages
	elseif ($messageLevel -eq 30 -and $script:LogLevel -le 30){
        if ($script:logFormattingOptions['PrefixCallingFunction'] = 1 -and !([string]::IsNullOrEmpty($callingFunction))){
            $FormatMessage = "$tabs$timeStamp[$callingFunction] $Message"
        }
        else{
		    $FormatMessage = "$tabs$timeStamp$Message"
        }
		Write-Error "$FormatMessage"
		if ($script:logTargetWinEvent -eq 1){
			Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Error" -EventId $eventID -Message "$FormatMessage"
			}
										 
																										
		 
	}
}export-modulemember -function Write-Log