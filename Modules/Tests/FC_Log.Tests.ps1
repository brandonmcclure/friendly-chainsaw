Remove-Module FC_Log -Force | Out-Null
Import-Module "$(Split-Path $PSScriptRoot -Parent)\FC_Log" -Force
Describe 'Write-Log to file' {

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
        BeforeEach {
            $file1 = "TestDrive:\FCTests\FCNewFolder\FCLogTest01.log"
            $file2 = "TestDrive:\FCTests\FCNewFolder\ANotherNewFolder\FCLogTest02.log"
            $filePath = $file1, $file2
            Remove-Item TestDrive:\* -Recurse -Force -ErrorAction Ignore | Out-Null
            Set-logTargets -File $filePath -Console 0
            Write-Log "Testing"
        }

        it "File 1" {
            Get-Content $file1 | Should -Be "Testing"
        }
        it "File 2" {
            Get-Content $file2 | Should -Be "Testing"
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

Describe 'Set-LogLevel' {
    COntext 'Valid input' {
        it 'Debug' {
            Set-LogLevel Debug
            Write-Log "Debug Test" Debug | Should --Be "Debug Test"
        }
    }
}