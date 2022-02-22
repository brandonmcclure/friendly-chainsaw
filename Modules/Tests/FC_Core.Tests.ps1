Remove-Module FC_Core -Force -ErrorAction Ignore | Out-Null
Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_Core" -Force

Set-logTargets -WindowsEventLog 0

Describe 'Get-FCSecret'{
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

Describe 'ConvertTo-HashTable'{

    Context 'Parameter validation'{
        it "Single File item"{
        #Notice that I am keeping the $testFileHash string aligned to the left, that is to ensure that the result from ConvertTo-HashTable are equivelant to the string, and not thrown off due to white space.
$testFileObject = [PSCustomObject]@{PSChildName = 'Test File.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
}
$testFIleHash = "[PSCustomObject]@{PSChildName = 'Test File.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
}"

            mock Get-ChildItem {return $testFileObject  }

            $result = Get-ChildItem 
            $result | ConvertTo-HashTableString -MockablePSObject | Should -Be $testFIleHash
            
        }
        it "Multiple File item"{
$testFileObject = ([PSCustomObject]@{PSChildName = 'Test File.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
},
[PSCustomObject]@{PSChildName = 'Test File2.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
}
)
$testFIleHash = "[PSCustomObject]@{PSChildName = 'Test File.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
},[PSCustomObject]@{PSChildName = 'Test File2.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
}"

            mock Get-ChildItem {return $testFileObject  }

            $result = Get-ChildItem 
            $result | ConvertTo-HashTableString -MockablePSObject | Should -Be $testFIleHash
            
        }       

    }

}