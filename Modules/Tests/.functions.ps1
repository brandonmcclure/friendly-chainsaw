function LoadLocalModules{
	Remove-Module FC_SysAdmin -Force -ErrorAction Ignore | Out-Null
	Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_SysAdmin" -Force -DisableNameChecking

	Remove-Module FC_TFS -Force -ErrorAction Ignore | Out-Null
		Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_TFS" -Force -DisableNameChecking

	Remove-Module FC_Log -Force -ErrorAction SilentlyContinue | Out-Null
	Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_Log" -Force -DisableNameChecking

	Remove-Module FC_Data -Force -ErrorAction SilentlyContinue | Out-Null
	Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_Data" -Force -DisableNameChecking

	Remove-Module FC_Core -Force -ErrorAction SilentlyContinue | Out-Null
	Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_Core" -Force -DisableNameChecking
}