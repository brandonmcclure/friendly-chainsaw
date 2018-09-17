function Update-ManifestFromConfig{
param($ManifestConfigPath,$ManifestPath,$moduleName)
    Write-Host "Loading configuration data from $ManifestConfigPath"
    $configData = Get-Content $ManifestConfigPath | ConvertFrom-Json
    if (Test-Path $ManifestPath){
        Write-Host "Manifest already exists"
        if (![string]::IsNullOrEmpty($configData.Author)){
            Update-ModuleManifest -Path $ManifestPath -Author $configData.Author
        }
        if (![string]::IsNullOrEmpty($configData.Description)){
            Update-ModuleManifest -Path $ManifestPath -Description $configData.Description
        }
        if (![string]::IsNullOrEmpty($moduleName)){
            Update-ModuleManifest -Path $ManifestPath -RootModule $moduleName
        }
        if (![string]::IsNullOrEmpty($configData.PSVersion)){
            Update-ModuleManifest -Path $ManifestPath -PowerShellVersion $configData.PSVersion
        }
    }
    else{
        New-ModuleManifest -Path $ManifestPath -Author $configData.Author -Description $configData.Description -RootModule $moduleName -ModuleVersion "1.0" -PowerShellVersion $configData.PSVersion -RequiredModules $configData.requiredModules -NestedModules $configData.nestedModules | Out-Null
    }
    Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
    Write-Host "Module manifest creation/testing complete"
}