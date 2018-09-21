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