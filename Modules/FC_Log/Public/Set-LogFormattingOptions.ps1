function Set-LogFormattingOptions{
<#
    .Synopsis
       Turns on or off the formatting options for the FC_log module. This controls how Write-Log formats the messages it logs.
	.Description
        This function only needs to be called once at the start of the script. You can set some or all of the options by only passing the parameters that correspond to the formatting option you want to enable.
	.PARAMETER PrefixCallingFunction
        Default: -1
        Position: 0

		When set to 1, Write-Log will format the message to include the calling function in the message. This is helpful when reading log output to help determine where the log message came from.
        When set to 0, it will explicitly turn off that formatting 
	.PARAMETER AutoTabCallsFromFunctions
        Default: -1
        Position: 1
		
        When set to 1, Write-Log will format the message to place 5 spaces at the front to form a graphical indicator of which functions are nested within each other.
        When set to 0, it will explicitly turn off that formatting
	.PARAMETER PrefixTimestamp
        Default: -1
        Position:  2

		When set to 1, Write-Log will format the message to place the contents of Get-Date at the front of the message. There is no control over the formatting of the date.
        When set to 0, it will explicitly turn off that formatting 
    .PARAMETER PrefixScriptName
        Default: -1
        Position:  2

		When set to 1, Write-Log will format the message to place the script name that the command was run from. 
        When set to 0, it will explicitly turn off that formatting 


    #>
    param([Parameter(Position=0)][int] $PrefixCallingFunction = -1,[Parameter(Position=1)][int] $AutoTabCallsFromFunctions = -1,[Parameter(Position=2)][int] $PrefixTimestamp = -1,[Parameter(Position=2)][int] $PrefixScriptName = -1)

    if ($PrefixCallingFunction -eq 1 -or $PrefixCallingFunction -eq 0){
        $script:logFormattingOptions['PrefixCallingFunction'] = $PrefixCallingFunction
    }
    if ($AutoTabCallsFromFunctions -eq 1 -or $AutoTabCallsFromFunctions -eq 0){
        $script:logFormattingOptions['AutoTabCallsFromFunctions'] = $AutoTabCallsFromFunctions
    }
    if ($PrefixTimestamp -eq 1 -or $PrefixTimestamp -eq 0){
        $script:logFormattingOptions['PrefixTimestamp'] = $PrefixTimestamp
    }
    if ($PrefixScriptName -eq 1 -or $PrefixScriptName -eq 0){
        $script:logFormattingOptions['PrefixScriptName'] = $PrefixScriptName
    }
}export-modulemember -Function Set-LogFormattingOptions