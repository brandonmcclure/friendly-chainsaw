function Get-CallingScript{
	
    $scriptName = (Get-PSCallStack | Where-Object { $_.Command.substring($_.Command.Length-3,3) -eq 'ps1'} | Select-Object -First 1  | select -ExpandProperty Command) -replace '.ps1',''

	if([string]::IsnullOrEmpty($scriptName)){
		$callstackCount = Get-PSCallStack| Where-Object { $_.Command -ne '<ScriptBlock>'} | Measure-OBject | select-object -ExpandProperty Count

		$scriptName = (Get-PSCallStack | Where-Object { $_.Command.substring($_.Command.Length-3,3) -eq 'ps1'} | Select-Object -First 1 -skip ($callstackCount-1)  | select -ExpandProperty Command) -replace '.ps1',''
	}
	if([string]::IsnullOrEmpty($scriptName)){

		$callstackCount = Get-PSCallStack| Where-Object { $_.Command -ne '<ScriptBlock>'} | Measure-OBject | select-object -ExpandProperty Count

		$scriptName = (Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>'} | Select-Object -First 1 -skip ($callstackCount-1)  | select -ExpandProperty Command)
	}
	if([string]::IsnullOrEmpty($scriptName)){
		Write-Log "Cannot get the calling script" Error -ErrorAction Stop
	}
    Write-Output $scriptName
}