
Describe 'Write-Log to file' {
	beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}

    Context 'Single File' {
        BeforeEach{
            $filePath = "TestDrive:\FCLogTest01.log"
            Remove-Item -Path TestDrive:\* -Force -ErrorAction Ignore | Out-Null
            Set-logTargets -File $filePath -Console 0
            Write-Log "Testing" 
        }
        it "Test file" {
            Get-Content $filePath | Should -Be "Testing"
        }
    }
    Context 'Multiple Files' {
        BeforeEach{
            $filePath = "TestDrive:\FCLogTest01.log", "TestDrive:\FCLogTest02.log"
            Remove-Item -Path TestDrive:\* -Force -ErrorAction Ignore | Out-Null
            Set-logTargets -File $filePath  -Console 0
            Write-Log "Testing"
        }

        it "File 1" {
            Get-Content "TestDrive:\FCLogTest01.log" | Should -Be "Testing"
        }
        it "File 2" {
            Get-Content "TestDrive:\FCLogTest02.log" | Should -Be "Testing"
        }
    }
    Context 'Create Folder if it does not exist' {

        it "Parent new folder" {
			$file = "TestDrive:\FCTests\FCNewFolder\FCLogTest01.log"
            $filePath = $file
            Remove-Item TestDrive:\* -Recurse -Force -ErrorAction Ignore | Out-Null
            Set-logTargets -File $filePath -Console 0
            Write-Log "Testing"
            Get-Content $file | Should -Be "Testing"
        }
        it "Nested new folders" {
			$file = "TestDrive:\FCTests\FCNewFolder\ANotherNewFolder\FCLogTest02.log"
			$filePath = $file
            Remove-Item TestDrive:\* -Recurse -Force -ErrorAction Ignore | Out-Null
            Set-logTargets -File $filePath -Console 0
            Write-Log "Testing"

            Get-Content $file | Should -Be "Testing"
        }
    }

    Context 'Multiple messages' {
        BeforeEach {
            $file1 = "TestDrive:\FCLogTest01.log"
            $file2 = "TestDrive:\FCLogTest02.log"
            $filePath = $file1, $file2
            Remove-Item TestDrive:\* -Recurse -Force -ErrorAction Ignore | Out-Null
            Set-logTargets -File $filePath -Console 0
            "test1", "test2" | Write-Log
        }

        it "File 1" {
            Get-Content $file1 | Should -Be "test1", "test2"
        }
        it "File 2" {
            Get-Content $file2 | Should -Be "test1", "test2"
        }
    }
}

Describe "Write-Log to event log"{
	beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}

	Context "Error on pqsh core"{
		It 'Throws error on pwsh core (non terminating error, made to terminate)'{
			Set-logTargets -WindowsEventLog 1 -ErrorAction Ignore;
			{Write-Log "Test" -ErrorAction Stop} | should -throw "I cannot log to the Windows Event Log on pwsh core without some workarounds. See https://github.com/brandonmcclure/friendly-chainsaw/issues/61"
		}
	}
}
Describe 'Set-LogLevel' {
	beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}

    COntext 'Debug' {
        it 'Out Verbose stream - Is there' {
            Set-LogLevel Debug
            Write-Log "Debug Test" Debug 4>&1 | Should -Be "[DEBUG] Debug Test"
        }
		it 'Out Verbose stream - Nothing on Output/success stream' {
            Set-LogLevel Debug
            Write-Log "Debug Test" Debug | Should -BeNullOrEmpty
        }
    }
	Context 'Verbose'{
		it 'Verbose' {
            Set-LogLevel Verbose
            Write-Log "Verbose Test" Verbose 4>&1 | Should -Be " Verbose Test"
        }
	}
	Context 'Info'{
		it 'Out Info stream' {
            Set-LogLevel Info
            Write-Log "Test" Info  6>&1| Should -Be "Test"
        }
	}
	Context 'Warning'{
		it 'Warning Stream - Is There' {
            Set-LogLevel Warning
            Write-Log "Test" Warning 3>&1 | Should -Be "[WARNING] Test"
        }
	}
	Context 'Error'{
		it 'Error Stream - Is there' {
            Set-LogLevel Error
            Write-Log "Test" Error 2>&1 | Should -Be "Test"
        }
	}
	Context 'Disable'{
		it 'Debug - Nothing on Output' {
            Set-LogLevel Disable
            Write-Log "Test" Debug | Should -BeNullOrEmpty
		}
		it 'Verbose - Nothing on Output' {
            Set-LogLevel Disable
            Write-Log "Test" Verbose | Should -BeNullOrEmpty
		}
		it 'Info - Nothing on Output' {
            Set-LogLevel Disable
            Write-Log "Test" Info | Should -BeNullOrEmpty
		}
		it 'Warning - Nothing on Output' {
            Set-LogLevel Disable
            Write-Log "Test" Warning | Should -BeNullOrEmpty
		}
		it 'Error - Nothing on Output' {
            Set-LogLevel Disable
            Write-Log "Test" Error | Should -BeNullOrEmpty
        }
	}
}

Describe 'Set-LogTarget'{
	beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}
	

	Context 'Speach'{
		it 'does not work on core'{
			{Set-logTargets -Speech 1 }| Should -throw "I cannot log to the Speech on pwsh core"
		}
	}
	Context 'Windows Event Log'{
		it 'does not work on core (non terminating error, made to terminate)'{
			{Set-logTargets -WindowsEventLog 1 -ErrorAction Stop }| Should -throw "I cannot log to the Windows Event Log on pwsh core without some workarounds. See https://github.com/brandonmcclure/friendly-chainsaw/issues/61"
		}
		it 'does not work on core (non terminating error)'{
			Set-logTargets -WindowsEventLog 1 -ErrorAction Ignore | Should -BeNullOrEmpty
		}
	}
	
}

Describe 'LogFormatting' {
    beforeall {
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
	}
    Context "PrefixScriptName" {        
        It "If can't Get-CallingScript, error" {
            mock -moduleName fc_log Get-CallingScript {return $null}

            Set-LogFormattingOptions -PrefixScriptName 1
            {Write-Log "Testing" Info 6>&1} | should -throw "Cannot set the scriptName"
        }
        It "Basic scope should return [Pester]" {

            Set-LogFormattingOptions -PrefixScriptName 1
            Write-Log "Testing" Info 6>&1 | should -be "[Pester] Testing"
        }
    }
}