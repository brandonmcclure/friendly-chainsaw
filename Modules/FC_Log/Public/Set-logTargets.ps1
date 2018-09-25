function Set-logTargets{
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


    #>
    param([Parameter(Position=0)][int] $Console = -1,
    [Parameter(Position=1)][int] $WindowsEventLog = -1,
    [Parameter(Position=2)][int] $File = -1,
    [Parameter(Position=3)][int] $Speech = -1)

    if ($Console -eq 1 -or $Console -eq 0){
        $script:logTargets['Console'] = $Console
    }
    if ($WindowsEventLog -eq 1 -or $WindowsEventLog -eq 0){
        $script:logTargets['WindowsEventLog'] = $WindowsEventLog
    }
    if ($File -eq 1 -or $File -eq 0){
        $script:logTargets['File'] = $File
    }
    if ($Speech -eq 1 -or $Speech -eq 0){
        $script:logTargets['Speech'] = $Speech
    }
}export-modulemember -Function Set-logTargets