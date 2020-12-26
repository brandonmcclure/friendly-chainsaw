Remove-Module FC_Core -Force -ErrorAction Ignore | Out-Null
Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_Core" -Force
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