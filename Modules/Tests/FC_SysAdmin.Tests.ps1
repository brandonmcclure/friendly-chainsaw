
# Describe 'Get-FileMetadata'{

#     Context 'Parameter validation'{
#         it "Null Inputs"{
#             Get-FileMetaData | Should -be $null
#             }
#     }
#     Context 'sdg'{
#     Class Folder
# {
#     #Start - Control Objects
#     [bool] $mockCloudWorkSpace
#     #End - Control Objects
 
#     #Start - Variables For tracking Function Calls
#     [bool] $isCalledGetCloudWorkSpace = $false
#     [bool] $isCalledAddCloudWorkSpace = $false
#     [bool] $isCalledRemoveOmsAgentWorkSpace =$false
#     [bool] $isCalledReloadConfiguration = $false
 
#     [bool] $isCalledWorkSpaceId = $false
#     [bool] $isCalledWorkSpaceKey = $false
#     #End - Variables For tracking Function Calls
    
#     [void] Items()
#     {

#     }
                  
# }
#         it "Test my test (Does my mocked COM object have the same methods as the real deal"{
#             $omsMockObject = [Folder]::new() | Get-Member -MemberType Method
#         $omsRealObject = New-Object -ComObject Shell.Application | Get-Member -MemberType Method -force
#             ForEach($omsMockObj in $omsMockObject) {
#             #Exclude methods automatically added to PowerShell Class
#             $autoAddedMethods = "GetHashCode","GetType","ToString"
#             if($omsMockObj.name -notin $autoAddedMethods) {
#                 It "$($omsMockObj.name) Exists In Original Class" {
#                     if(($omsRealObject | Where-Object { $_.name -eq $omsMockObj.name }))
#                     {
#                         $result = $true
#                     }
#                     else
#                     {
#                         $result = $false
#                     }
 
#                     $result | Should -be $true
#                 }
#             }
#         }
            
           
#         }
#         it 'tv2'{
#             Mock -ModuleName FC_SysAdmin Get-ShellFolder {return [psobject]@{CopyHere = 'void CopyHere (Variant, Variant)'
# DismissedWebViewBarricade = 'void DismissedWebViewBarricade ()'
# GetDetailsOf = 'string GetDetailsOf (Variant, int)'
# Items = 'FolderItems Items ()'
# MoveHere = 'void MoveHere (Variant, Variant)'
# NewFolder = 'void NewFolder (string, Variant)'
# ParseName = 'FolderItem ParseName (string)'
# Synchronize = 'void Synchronize ()'
# Application = 'System.__ComObject'
# HaveToShowWebViewBarricade = 'False'
# OfflineStatus = ''
# Parent = ''
# ParentFolder = 'System.__ComObject'
# Self = 'System.__ComObject'
# ShowWebViewBarricade = 'False'
# Title = 'brandon'
# }}

# $testFileObject = [PSCustomObject]@{PSChildName = 'Test File.txt'
# PSIsContainer = 'False'
# PSParentPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
# PSPath = 'Microsoft.PowerShell.Core\FileSystem::\\10.10.10.10\the\path\to\the\file'
# PSProvider = 'Microsoft.PowerShell.Core\FileSystem'
# }
#         Mock Get-ChildItem {return $testFileObject}
#         Get-ChildItem | Get-FileMetaData
#         }
#     }
# }
# }

Describe 'Backup Functionality' {

	BeforeEach {
		function GetFullPath {
			Param(
				[string] $Path
			)
			return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
		}
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
		
		Set-logTargets -WindowsEventLog 0 -Console 0
		$testDir = "TestDrive:\src"
		$numOfDirs = 5
		$numOfFiles = 10
		$j = $null
		$j = Get-BackupJob -Name TestJob 
		if ($j -ne $null){
			$j| Remove-BackupJob
		}
		function mkfile {
			param($dirPath)
			if (-not (Test-Path $dirPath)) { New-Item $dirPath -Force -ItemType Directory }

			foreach ($f in 1..$numOfFiles) {
				$filePath = "$dirPath\$f.txt"
				$file = [io.file]::Create($(GetFullPath $filePath))
				$file.SetLength(100kb)
				$file.Close()
			}
		}
		foreach ($d in 1..$numOfDirs) {
			$dirPath = "$testDir\$d"
			mkfile -dirPath $dirPath

			foreach ($subDir in 1..$numOfDirs) {
				$dirPath = "$testDir\$d\$subDir"
				mkfile -dirPath $dirPath
		
			}
		}
	}

	# Context "ContextName" {
	# 	It "if anchorBackupDirectory does not exist, create it" {
	# 		Assertion
	# 		should -Invoke Get-ChildItem -Exactly -Times 1
	# 	}
	# }
	Context 'New-BackupJob' {
		It 'Got my data setup right' {
			$files = Get-ChildITem -recurse -path TestDrive:\src -File
			$ShouldCount = (($numOfDirs * $numOfDirs) * $numOfFiles ) + ($numOfDirs * $numOfFiles)
			
			($files | Measure-Object | Select -ExpandProperty Count ) | Should -Be $ShouldCount
		}
		It 'Integration test' {
			#Get-BackupJob -Name TestJob -ErrorAction SilentlyContinue | Remove-BackupJob -ErrorAction SilentlyContinue | Out-Null
			New-BackupJob -Name TestJob -SourcePath TestDrive:\src -DestinationPath TestDrive:\dest -BackupProvider pwsh

			Get-BackupJob TestJob | invoke-BackupJob 

			$files = Get-ChildITem -recurse -path TestDrive:\dest -File
			$ShouldCount = (($numOfDirs * $numOfDirs) * $numOfFiles ) + ($numOfDirs * $numOfFiles)+ 2
			
			($files | Measure-Object | Select -ExpandProperty Count ) | Should -Be $ShouldCount

			$x = 0;
		}
	}

}
	