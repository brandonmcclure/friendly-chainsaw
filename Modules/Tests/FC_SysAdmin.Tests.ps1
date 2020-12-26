Remove-Module FC_SysAdmin -Force -ErrorAction Ignore | Out-Null
Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_SysAdmin" -Force
Describe 'Get-FileMetadata'{

    Context 'Parameter validation'{
        it "Null Inputs"{
            Get-FileMetaData | Should -be $null
            }
    }
    Context 'sdg'{
    Class Folder
{
    #Start - Control Objects
    [bool] $mockCloudWorkSpace
    #End - Control Objects
 
    #Start - Variables For tracking Function Calls
    [bool] $isCalledGetCloudWorkSpace = $false
    [bool] $isCalledAddCloudWorkSpace = $false
    [bool] $isCalledRemoveOmsAgentWorkSpace =$false
    [bool] $isCalledReloadConfiguration = $false
 
    [bool] $isCalledWorkSpaceId = $false
    [bool] $isCalledWorkSpaceKey = $false
    #End - Variables For tracking Function Calls
    
    [void] Items()
    {

    }
                  
}
        it "Test my test (Does my mocked COM object have the same methods as the real deal"{
            $omsMockObject = [Folder]::new() | Get-Member -MemberType Method
        $omsRealObject = New-Object -ComObject Shell.Application | Get-Member -MemberType Method -force
            ForEach($omsMockObj in $omsMockObject) {
            #Exclude methods automatically added to PowerShell Class
            $autoAddedMethods = "GetHashCode","GetType","ToString"
            if($omsMockObj.name -notin $autoAddedMethods) {
                It "$($omsMockObj.name) Exists In Original Class" {
                    if(($omsRealObject | Where-Object { $_.name -eq $omsMockObj.name }))
                    {
                        $result = $true
                    }
                    else
                    {
                        $result = $false
                    }
 
                    $result | Should -be $true
                }
            }
        }
            
           
        }
        it 'tv2'{
            Mock -ModuleName FC_SysAdmin Get-ShellFolder {return [psobject]@{CopyHere = 'void CopyHere (Variant, Variant)'
DismissedWebViewBarricade = 'void DismissedWebViewBarricade ()'
GetDetailsOf = 'string GetDetailsOf (Variant, int)'
Items = 'FolderItems Items ()'
MoveHere = 'void MoveHere (Variant, Variant)'
NewFolder = 'void NewFolder (string, Variant)'
ParseName = 'FolderItem ParseName (string)'
Synchronize = 'void Synchronize ()'
Application = 'System.__ComObject'
HaveToShowWebViewBarricade = 'False'
OfflineStatus = ''
Parent = ''
ParentFolder = 'System.__ComObject'
Self = 'System.__ComObject'
ShowWebViewBarricade = 'False'
Title = 'brandon'
}}

$testFileObject = [PSCustomObject]@{PSChildName = 'Test File.txt'
PSIsContainer = 'False'
PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
}
        Mock Get-ChildItem {return $testFileObject}
        Get-ChildItem | Get-FileMetaData
        }
    }
}
Describe 'Invoke-IncrementalFileBackup'{
    Context 'Parameter Validation'{
        It 'Null Inputs -eq null out'{
             Invoke-IncrementalFileBackup
        }
    }

}