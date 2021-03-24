[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [parameter(Mandatory=$false)][string[]] $moduleName = $null
    ,[string] $moduleAuthor = "Brandon McClure"
    ,$apiKey
    )

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
$origLocation = Get-Location
    if ([string]::IsNullOrEmpty($moduleName)) {
		$modules = Get-ChildItem -Path $pathToSearch  -Recurse | where { $_.Extension -eq '.psm1' }
	}
	else {
		$modules = Get-ChildItem -Path $pathToSearch  -Recurse | where { $_.Extension -eq '.psm1' -and $_.Name -in $moduleName }
	}
	foreach ($module in $modules) {
    Publish-Module -Name $module -NuGetApiKey $apiKey -ErrorAction Continue
    }


Set-Location $origLocation