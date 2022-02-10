param(
	$moduleName = "FC_YNAB",
	$moduleRootPath
	)

if([string]::IsNullOrEmpty($moduleName)){
	Write-Log "You must pass the moduleName" Error -ErrorAction Stop
}

if([string]::IsNullOrEmpty($moduleRootPath)){
	Write-Log "Settings the path relative to this script"
	$moduleRootPath = "$(Split-Path $PSScriptRoot -Parent)\Modules"
}

$modulePath = "$moduleRootPath\$moduleName"
Write-Log "Creating the directory $modulePath"
New-Item -Path $modulePath -ItemType Directory -ErrorAction Stop