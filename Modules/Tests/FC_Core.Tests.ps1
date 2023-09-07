Describe 'Get-FCSecret'{
    beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}
    Context "ContextName" {
        beforeEach{
            Set-SecretStoreConfiguration -Authentication None -Confirm:$false -Interaction "None"

            Unregister-SecretVault -Name "Pester_test" -ErrorAction SilentlyContinue
            Register-SecretVault -Name "Pester_test" -ModuleName Microsoft.PowerShell.SecretStore 
        }
        It "Null Name Input throws error"{
            $scriptBlock = {Get-FCSecret -ErrorAction Stop }
            $scriptBlock | Should -throw "You must pass a value to the name parameter"
        }
        It "sleep for 10 seconds"{
            mock -ModuleName FC_Core Start-Sleep {} 
             Get-FCSecret -Name "test" -VaultName "Pester_test" -ErrorAction Stop 
            Assert-MockCalled -ModuleName FC_Core Start-Sleep -Exactly 10
        }
        it "Should error if cannot find secret"{
            $scriptBlock = {Get-FCSecret -Name "Test" -VaultName "Pester_test" -ErrorAction Stop }
            $scriptBlock | Should -throw "The secret test was not found."
        }
    }
}

Describe 'Start-MyProcess' {
	beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}

    Context 'basics' {
        it "No EXEPath in, error thrown" {
            {Start-MyProcess} | Should -throw "EXEPath not set"
        }
        it "EXEPath is garbage, error thrown" {
            {Start-MyProcess -EXEPath 'doesnotexist'} | Should -throw "EXEPath not a valid path"
        }
    }
}
