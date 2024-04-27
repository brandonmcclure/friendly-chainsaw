[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$false)][string[]] $moduleName = 'fc_core'
    ,[string] $moduleAuthor = "Brandon McClure"
    ,[securestring]$apiKey
	,$pathToSearch = '${PWD}'
	,$repositoryName = 'PSGalery'
    )

	if([string]::IsNullOrEmpty($apiKey)){
		$apiKey = Read-Host -Prompt "Please enter $repositoryName API key" -MaskInput | ConvertTo-SecureString -AsPlainText
	}
if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
$origLocation = Get-Location
    if ([string]::IsNullOrEmpty($moduleName)) {
		$modules = Get-ChildItem $PSScriptRoot -Recurse | where { $_.Extension -eq '.psm1' }
	}
	else {
		$modules = Get-ChildItem $PSScriptRoot -Recurse | where { $_.Extension -eq '.psm1' -and $_.BaseName -in $moduleName }
	}

	$moduleCount = $modules | Measure-Object | Select-Object -ExpandProperty Count
	Write-Log "Found $moduleCount modules."
	foreach ($module in $modules) {
		Write-Log "Publishing module: $module"
    	Publish-Module -repository $repositoryName -Name $module -NuGetApiKey ($apiKey | ConvertFrom-SecureString -AsPlainText) -ErrorAction Continue
    }


Set-Location $origLocation