[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$true)][string] $moduleName = $null
    ,[parameter(Mandatory=$true)][string]$moduleDescription = $null
    ,[string] $moduleAuthor = "Brandon McClure"
    )
$version = $null
$hashFilePath = "moduleHashHistory.xml"
$ManifestPath = ".\$moduleName\$moduleName.psd1"
$ModulePath = ".\$moduleName\$moduleName.psm1"


Remove-Variable moduleHashHistory -ErrorAction Ignore
$moduleHashHistory = Import-Clixml -Path $hashFilePath

if($version -eq $null){
    $currModuleHash = Get-FileHash -Path $ModulePath -Algorithm SHA256
    $currModuleHash | Add-Member -MemberType NoteProperty -name version -Value 1.0

    $previousHash = $moduleHashHistory | where moduleName -eq $moduleName

    if([string]::IsNullOrEmpty($previousHash)){
        $moduleHashHistory += $currModuleHash
    }
}

Export-Clixml -InputObject $moduleHashHistory -Path $hashFilePath
New-ModuleManifest -Path $ManifestPath -Author $moduleAuthor -Description $moduleDescription -FunctionsToExport "*"