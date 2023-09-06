function Get-CallingFunction{
    $callingFunction = (Get-PSCallStack | Select-Object -Skip 2 -First 1 | Where-Object { $_.Command -ne '<ScriptBlock>' }).FunctionName 
    Write-Output $callingFunction
}