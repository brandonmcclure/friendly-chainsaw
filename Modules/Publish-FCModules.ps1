[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$true)][string] $moduleName = $null
    ,[parameter(Mandatory=$true)][string]$moduleDescription = $null
    ,[string] $moduleAuthor = "Brandon McClure"
    )
$version = $null
$moduleVersion = $null
$moduleName = 'FC_Log'
$ManifestPath = ".\Modules\$moduleName\$moduleName.psd1"
$ModulePath = ".\Modules\$moduleName\$moduleName.psm1"
Remove-Variable moduleHashHistory
$moduleHashHistory = @()
$moduleHashHistory += Import-Clixml -Path '.\modules\moduleHashHistory.xml'
$previousHash = $moduleHashHistory | where moduleName -eq $moduleName

$currModule = New-Object System.Object


    $currModuleHash = Get-FileHash -Path $ModulePath -Algorithm SHA256
    $currModule | Add-Member -Type NoteProperty -Name ModuleName -Value $moduleName
    $currModule | Add-Member -Type NoteProperty -Name HashDatetime -Value (Get-Date )
    $currModule | Add-Member -Type NoteProperty -Name HashValue -Value $currModuleHash.Hash
    $currModule | Add-Member -Type NoteProperty -Name HashAlgorithm -Value $currModuleHash.Algorithm
    $currModule | Add-Member -Type NoteProperty -name ModuleMajorVersion -Value 1
    $currModule | Add-Member -Type NoteProperty -name ModuleMinorVersion -Value "0"
    $currModule | Add-Member -Type NoteProperty -name ModuleMinorMinorVersion -Value "0"
    $currModule | Add-Member -Type NoteProperty -name ModuleVersion -Value "$($currModule.ModuleMajorVersion).$($currModule.ModuleMinorVersion).$($currModule.ModuleMinorMinorVersion)"
    $currModule | Add-Member -Type NoteProperty -name PSVersion -Value "4.0"
    $currModule | Add-Member -Type NoteProperty -name requiredModules -Value @('ModuleName=”FC_Core”')
    $currModule | Add-Member -Type NoteProperty -name NestedModules -Value @('ModuleName=”FC_Core”')

    $export = 0
    if ($previousHash -eq $null){
        $export = 1
        $currModule.ModuleMinorMinorVersion = 0
        $currModule.ModuleMinorVersion = 0
        $currModule.ModuleMajorVersion = 1
        $currModule.ModuleVersion = "$($currModule.ModuleMajorVersion).$($currModule.ModuleMinorVersion).$($currModule.ModuleMinorMinorVersion)"
    }
    elseif($previousHash.HashValue -ne $currModule.HashValue){
        $export = 1
        $currModule.ModuleMinorMinorVersion = $previousHash.ModuleMinorMinorVersion + 1
        $currModule.ModuleMinorVersion = $previousHash.ModuleMinorVersion
        $currModule.ModuleMajorVersion = $previousHash.ModuleMajorVersion
        $currModule.ModuleVersion = "$($currModule.ModuleMajorVersion).$($currModule.ModuleMinorVersion).$($currModule.ModuleMinorMinorVersion)"
    }
    
    if ($export -eq 1){
        Write-Host "Saving hash history, and creating the manifest"
        $moduleHashHistory += $currModule

        Export-Clixml -InputObject $moduleHashHistory -Path '.\modules\moduleHashHistory.xml'
        New-ModuleManifest -Path $ManifestPath -Author "Brandon McClure" -Description "Logging utility" -ModuleVersion $currModule.ModuleVersion -PowerShellVersion $currModule.PSVersion -RequiredModules $currModule.requiredModules -NestedModules $currModule.nestedModules
        Test-ModuleManifest -Path $ManifestPath -Verbose
    }

Export-Clixml -InputObject $moduleHashHistory -Path $hashFilePath
New-ModuleManifest -Path $ManifestPath -Author $moduleAuthor -Description $moduleDescription -FunctionsToExport "*"