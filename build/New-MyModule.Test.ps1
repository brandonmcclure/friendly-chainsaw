Describe "New-MyModule" {
	Context "parameterValidation - moduleName" {
		It "blank moduleName will error" {
			$scriptBlock = { . "$PSScriptRoot\New-MyModule.ps1" -moduleName "" }
			$scriptBlock | should -throw "You must pass the moduleName"
		}
		It "blank moduleName will error" {
			$scriptBlock = { . "$PSScriptRoot\New-MyModule.ps1" -moduleName $null }
			$scriptBlock | should -throw "You must pass the moduleName"
		}
		# It "No default value for moduleName is stored with the script" {
		# 	$scriptBlock = { . "$PSScriptRoot\New-MyModule.ps1" }
		# 	$scriptBlock | should -throw "You must pass the moduleName"
		# }
	}
	Context "parameterValidation - modulePath" {
		BeforeEach{
			$moduleName = "FC_Test"
			$testModuleRootPath = "TestDrive:\modules"

			$ParamFilterNewItem_DefaultModuleDirectoryPath = {$InputObject.Path -eq "$(Split-Path $PSScriptRoot -Parent)\Modules" -and $InputObject.ItemType -eq 'Directory' -and $InputObject.ErrorAction -eq 'Stop'}

			$ParamFilterWriteLog_CreatingLiteralModuleRootPath = {$Messages -eq "Creating the directory $testModuleRootPath"}
			$ParamFilterWriteLog_RelativeModuleRootPath = {$Messages -eq "Settings the path relative to this script"}

			Mock -CommandName 'New-Item'

		}

		It "blank moduleName will error" {
			Mock -CommandName 'Write-Log' -MockWith {} -Verifiable -ParameterFilter $ParamFilterWriteLog_RelativeModuleRootPath

			. "$PSScriptRoot\New-MyModule.ps1" -moduleName $moduleName -moduleRootPath ""
			Assert-MockCalled -CommandName 'New-Item' -Times 1 -Exactly #-ParameterFilter $ParamFilterNewItem_DefaultModuleDirectoryPath
			Assert-MockCalled -CommandName 'Write-Log' -Times 1 -Exactly -ParameterFilter $ParamFilterWriteLog_RelativeModuleRootPath
			
		}
		It "null moduleName will error" {
			
			Mock -CommandName 'Write-Log' -MockWith {} -Verifiable -ParameterFilter $ParamFilterWriteLog_RelativeModuleRootPath
			. "$PSScriptRoot\New-MyModule.ps1" -moduleName $moduleName -moduleRootPath $null 
			Assert-MockCalled -CommandName 'New-Item' -Times 1 -Exactly #-ParameterFilter $ParamFilterNewItem_DefaultModuleDirectoryPath 
			Assert-MockCalled -CommandName 'Write-Log' -Times 1 -Exactly -ParameterFilter $ParamFilterWriteLog_RelativeModuleRootPath
		}
		# It "No default value for moduleName is stored with the script" {
		# 	$scriptBlock = { . "$PSScriptRoot\New-MyModule.ps1" }
		# 	$scriptBlock | should -throw "You must pass the moduleName"
		# }
	}
	Context "Expected Files/Folders" {
		BeforeEach{
			$moduleName = "FC_Test"
			$testModuleRootPath = "TestDrive:\modules"

			$ParamFilterWriteLog_CreatingLiteralModuleRootPath = {$Messages -eq "Creating the directory $testModuleRootPath\$moduleName"}

		}
		It "Folder is created" {
			Mock -CommandName 'Write-Log' -MockWith {} -Verifiable -ParameterFilter $ParamFilterWriteLog_CreatingLiteralModuleRootPath

			. "$PSScriptRoot\New-MyModule.ps1" -moduleName $moduleName -moduleRootPath $testModuleRootPath

			Assert-MockCalled -CommandName 'Write-Log' -Times 1 -Exactly -ParameterFilter $ParamFilterWriteLog_CreatingLiteralModuleRootPath

			Get-ChildItem $testModuleRootPath | Measure-Object | Select-Object -ExpandProperty Count | SHould -be 1
		}
	}
}