[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$false)][string] $moduleName = $null
    ,[parameter(Mandatory=$false)][string]$moduleDescription = $null
    ,[string] $moduleAuthor = "Brandon McClure"
    ,[switch] $forceExport
    )

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
$origLocation = Get-Location
try{
    $modules = Get-ChildItem -Recurse | where {$_.Extension -eq '.psm1'}
    foreach($module in $modules){
        $ModuleName = $module.BaseName 
        $modulePath = $module.FullName
        $moduleDir = Split-Path $module.FullName -Parent
        $ManifestPath = "$moduleDir\$moduleName.psd1"
        $ManifestConfigPath = "$moduleDir\moduleManifest.json"
        
        Write-Host "Checking the $ModuleName module"
        Write-Host "At: $modulePath"
        
        Write-Host "Does a module manifest exist?"
        If(!(Test-Path $ManifestPath)){
            Write-Host "Manifest does not exist, does a configuration exist?"
            If(!(Test-Path $ManifestConfigPath)){
                Write-Host "Manifest config does not exist, skipping"
                break
            }

            $configData = Get-Content $ManifestConfigPath | ConvertFrom-Json

            New-ModuleManifest -Path $ManifestPath -Author $configData.Author -Description $configData.Description -RootModule $moduleName -ModuleVersion "1.0" -PowerShellVersion $configData.PSVersion -RequiredModules $configData.requiredModules -NestedModules $configData.nestedModules | Out-Null
            Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
            Write-Log "Module manifest creation/testing complete"

        }

        Import-Module $modulePath -ErrorAction Stop
        $commandList = Get-Command -Module $ModuleName
        Remove-Module $ModuleName

        Write-Output 'Calculating fingerprint'
        $fingerprint = foreach ( $command in $commandList )
        {
            foreach ( $parameter in $command.parameters.keys )
            {
                '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                $command.parameters[$parameter].aliases | 
                    Foreach-Object { '{0}:{1}' -f $command.name, $_}
            }
        }
        if ( Test-Path "$moduleDir\fingerprint" )
        {
            $oldFingerprint = Get-Content "$moduleDir\fingerprint"
        }
        $bumpVersionType = ''

        $fingerprint | Where {$_ -notin $oldFingerprint } | 
            ForEach-Object {$bumpVersionType = 'Patch'; "  $_"}
        'Detecting new features'
        $fingerprint | Where {$_ -notin $oldFingerprint } | 
            ForEach-Object {$bumpVersionType = 'Minor'; "  $_"}
        'Detecting breaking changes'
        $oldFingerprint | Where {$_ -notin $fingerprint } | 
            ForEach-Object {$bumpVersionType = 'Major'; "  $_"}

        Set-Content -Path "$moduleDir\fingerprint" -Value $fingerprint

        if (!([string]::IsNullOrEmpty($bumpVersionType))){
            Step-ModuleVersion -Path $ManifestPath -By $bumpVersionType
        }
    }
}
catch{
    $ex = $_.Exception
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    $errorMessage = $ex.Message 

    Set-Location $origLocation
    Write-Log "Error detected at line $errorLine, Error message: $errorMessage" Error -ErrorAction Stop
}

Set-Location $origLocation