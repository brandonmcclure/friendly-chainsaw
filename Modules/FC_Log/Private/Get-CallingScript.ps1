function Get-CallingScript{
    $scriptName = (Get-PSCallStack | Where-Object { $_.Command.substring($_.Command.Length-3,3) -eq 'ps1'} | Select-Object -First 1  | select -ExpandProperty Command) -replace '.ps1',''
    Write-Output $scriptName
}