[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$false)][string] $moduleName = 'FC_Log'#$null
    ,[parameter(Mandatory=$false)][string]$moduleDescription = 'Logging utility for my PS scripts. for when -Verbose and -Debug just dont cut it' #$null
    ,[string] $moduleAuthor = "Brandon McClure"
    ,[switch] $forceExport = $true
    )

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
$origLocation = Get-Location
try{
    $version = $null
    $moduleVersion = $null
    $ManifestPath = ".\Modules\$moduleName\$moduleName.psd1"
    $ModulePath = ".\Modules\$moduleName\$moduleName.psm1"
    $moduleHashHistoryPath = '.\modules\moduleHashHistory.xml'
    Remove-Variable moduleHashHistory,previousHash,functionsToExport -ErrorAction Ignore
    $moduleHashHistory = @()
    if (!(Test-Path $moduleHashHistoryPath)){
        Write-Log "The history file could not be found at $moduleHashHistoryPath, creating a new one" Warning
    }
    else{
        $moduleHashHistory += Import-Clixml -Path $moduleHashHistoryPath
    }
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
    $currModule | Add-Member -Type NoteProperty -name requiredModules -Value @()
    $currModule | Add-Member -Type NoteProperty -name NestedModules -Value @()

    if ($forceExport){
        $export = 1
    }
    else{
        $export = 0
    }
    if ($previousHash -eq $null){
        Write-Log "Previous hash does not exist for this module, setting the version to 1.0.0" Debug
        $export = 1
        $currModule.ModuleMinorMinorVersion = 0
        $currModule.ModuleMinorVersion = 0
        $currModule.ModuleMajorVersion = 1
        $currModule.ModuleVersion = "$($currModule.ModuleMajorVersion).$($currModule.ModuleMinorVersion).$($currModule.ModuleMinorMinorVersion)"
    }
    elseif($previousHash.HashValue -ne $currModule.HashValue){
        Write-Log "Previous hash does not match the current hash. Incrementing the minor minor version. Previous version: $($previousHash.ModuleVersion)" Debug
        $export = 1
        $currModule.ModuleMinorMinorVersion = $previousHash.ModuleMinorMinorVersion + 1
        $currModule.ModuleMinorVersion = $previousHash.ModuleMinorVersion
        $currModule.ModuleMajorVersion = $previousHash.ModuleMajorVersion
        $currModule.ModuleVersion = "$($currModule.ModuleMajorVersion).$($currModule.ModuleMinorVersion).$($currModule.ModuleMinorMinorVersion)"
    }
    
    
    if ($export -eq 1){
        #Get functions to export
        $functionsToExport = @()
        $moduleCode = Get-Content $ModulePath #| foreach { if ($_ -like "*Export-ModuleMember*"){$functionsToExport += $_} }
        [string]$regex = '.+Export-ModuleMember +-Function ([a-z-]+)'
        $myMatches = [regex]::Match($moduleCode,$regex)
        $myMatches.Groups[1].Value
        foreach ($m in $($myMatches.Groups)){
            Write-Log "$m"
        }
        foreach ($a in $functionsToExport){ $b = $a  | Select-String -Pattern "-Function "
Write-Log "$a | $b" }
        Write-Log "Saving hash history, creating the manifest, and testing."
        $functionsToExport = 'Write-Log'
        $moduleHashHistory = $moduleHashHistory | where {$_.ModuleName -ne $moduleName }
        $moduleHashHistory += $currModule

        Export-Clixml -InputObject $moduleHashHistory -Path $moduleHashHistoryPath
        
        New-ModuleManifest -Path $ManifestPath -Author $moduleAuthor -Description $moduleDescription -RootModule $moduleName -ModuleVersion $currModule.ModuleVersion -PowerShellVersion $currModule.PSVersion -RequiredModules $currModule.requiredModules -NestedModules $currModule.nestedModules | Out-Null
        Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
        Write-Log "Module manifest creation/testing complete"
    }
    else{
        Write-Log "No changes were detected in the module file. Skipping manifest creation"
        Set-Location $origLocation
        return
   }

    Set-Location ".\Modules\$moduleName"
    Write-Log "Creating the nuget package"
    #https://roadtoalm.com/2017/05/02/using-vsts-package-management-as-a-private-powershell-gallery/#comments
    nuget spec $moduleName -Force

    [string]$nugetHack = Get-Content "$moduleName.nuspec"
    $a = $nugetHack.replace("1.0.0" ,"$($currModule.ModuleVersion)") 
$a | Set-Content "$moduleName.nuspec" -Force
    nuget pack
}
catch{
    $ex = $_.Exception
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    $errorMessage = $ex.Message 

    Set-Location $origLocation
    Write-Log "Error detected at line $errorLine, Error message: $errorMessage" Error -ErrorAction Stop
}

Set-Location $origLocation