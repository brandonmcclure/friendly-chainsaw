[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$false)][string[]] $moduleName = "FC_Data.psm1"
    ,[parameter(Mandatory=$false)][string]$moduleDescription = $null
    ,[string] $moduleAuthor = "Brandon McClure"
    ,[switch] $forceConfigUpdate = $true
    )

Import-Module BuildHelpers -ErrorAction Stop
$pathToSearch = (Split-Path $PSCommandPath -Parent)
. $pathToSearch\BuildFunctions.ps1
$origLocation = Get-Location

try{
    if ([string]::IsNullOrEmpty($moduleName)){
    $modules = Get-ChildItem -Path $pathToSearch  -Recurse | where {$_.Extension -eq '.psm1'}
    }
    else{
        $modules = Get-ChildItem -Path $pathToSearch  -Recurse | where {$_.Extension -eq '.psm1' -and $_.Name -in $moduleName}
    }
    foreach($module in $modules){
        $ModuleName = $module.BaseName 
        $modulePath = $module.FullName
        $moduleDir = Split-Path $module.FullName -Parent
        $ManifestPath = "$moduleDir\$moduleName.psd1"
        $ManifestConfigPath = "$moduleDir\moduleManifest.json"
        $updateManifestFromConfig = 0
        
        Write-Host "Checking the $ModuleName module"
        Write-Host "At: $modulePath"
        
        Write-Host "Does a module manifest exist?"
        If(!(Test-Path $ManifestPath)){
            Write-Host "Manifest does not exist, does a configuration exist?"
            If(!(Test-Path $ManifestConfigPath)){
                Write-Host "Manifest config does not exist, skipping"
                break
            }

            $updateManifestFromConfig = 1
        }

        if ($updateManifestFromConfig -eq 1 -or $forceConfigUpdate){
            if ($forceConfigUpdate){
                Write-Host "Forcibly updating the manifest from the config if it exists"
            }
            If(!(Test-Path $ManifestConfigPath)){
                Write-Host "Manifest config does not exist, skipping"
            }
            else{
                Update-ManifestFromConfig -ManifestConfigPath $ManifestConfigPath -ManifestPath $ManifestPath -moduleName $moduleName
            }
        }

        Import-Module $modulePath -ErrorAction Stop
        $commandList = Get-Command -Module $ModuleName
        Remove-Module $ModuleName

        Update-ModuleManifest -Path $ManifestPath -FunctionsToExport $commandList

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
    Write-Error "Error detected at line $errorLine, Error message: $errorMessage" -ErrorAction Stop
}

Set-Location $origLocation