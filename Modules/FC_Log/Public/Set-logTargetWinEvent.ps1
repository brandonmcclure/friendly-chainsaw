function Set-logTargetWinEvent{
    <#
    .Synopsis
     The Set-LogTargetWinEvent function is deprecated. Please use the Set-logTargets function
    #>
	Param([Parameter(Position=0)][bool] $onoff)
	
    Write-Warning "The Set-LogTargetWinEvent function is deprecated. Please use the Set-logTargets function"
}export-modulemember -Function Set-logTargetWinEvent