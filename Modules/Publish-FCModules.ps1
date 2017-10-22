$version = $null
$moduleName = 'FC_Log'
$ManifestPath = ".\Modules\$moduleName\$moduleName.psd1"
$ModulePath = ".\Modules\$moduleName\$moduleName.psm1"
Remove-Variable moduleHashHistory
$moduleHashHistory = Import-Clixml -Path 'E:\Collect It\moduleHashHistory.xml'

if($version -eq $null){
    $currModuleHash = Get-FileHash -Path $ModulePath -Algorithm SHA256
    $currModuleHash | Add-Member -MemberType NoteProperty -name version -Value 1.0

    $previousHash = $moduleHashHistory | where moduleName -eq $moduleName

    if([string]::IsNullOrEmpty($previousHash)){
        $moduleHashHistory += $currModuleHash
    }
}

Export-Clixml -InputObject $moduleHashHistory -Path 'E:\Collect It\moduleHashHistory.xml'
New-ModuleManifest -Path $path -Author "Brandon McClure" -Description "Logging utility"