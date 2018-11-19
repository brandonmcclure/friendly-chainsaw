param([string[]]$paths = "Modules\Tests\FC_Data.Tests.ps1")
Import-Module Pester

if([string]::IsNullOrEmpty($paths)){
Invoke-Pester (Split-Path $PSCommandPath -Parent) -Verbose
return
}
foreach($path in $paths){
Invoke-Pester "$(Split-Path $PSCommandPath -Parent)\$path" -Verbose
}