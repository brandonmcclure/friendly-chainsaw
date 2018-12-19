param([string[]]$paths = "Modules\Tests\FC_SysAdmin.Tests.ps1")
Remove-Module Pester -Force | Out-Null
Import-Module Pester -Force

if([string]::IsNullOrEmpty($paths)){
Invoke-Pester (Split-Path $PSCommandPath -Parent) -Verbose
return
}
foreach($path in $paths){
Invoke-Pester "$(Split-Path $PSCommandPath -Parent)\$path" -Verbose
}