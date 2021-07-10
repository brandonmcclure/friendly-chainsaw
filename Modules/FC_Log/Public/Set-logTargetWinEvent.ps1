function Set-logTargetWinEvent{
    <#
    .Synopsis
     The Set-LogTargetWinEvent function is deprecated. Please use the Set-logTargets function
    #>
	Param([Parameter(Position=0)][bool] $onoff)
	
    Write-Warning "The Set-LogTargetWinEvent function is deprecated. Please use the Set-logTargets function. ie: if (`$winEventLog) { Set-logTargets -WindowsEventLog 1 }"
}