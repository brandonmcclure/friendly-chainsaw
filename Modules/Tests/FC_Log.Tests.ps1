Remove-Module FC_Log -Force | Out-Null
Import-Module FC_Log -Force
Describe 'Write-Log to file'{

    Context 'Single File'{
        $filePath = "$env:TEMP\FCLogTest01.log"
        Remove-Item $filePath -Force -ErrorAction Ignore | Out-Null
        Set-logTargets -File $filePath -Console 0
        Write-Log "Testing" 

        it "Test file"{
            Get-Content $filePath | Should Be "Testing"
            }
        }
Context 'Multiple Files'{
        $filePath = "$env:TEMP\FCLogTest01.log","$env:TEMP\FCLogTest02.log"
        Remove-Item $filePath -Force -ErrorAction Ignore | Out-Null
        Set-logTargets -File $filePath  -Console 0
        Write-Log "Testing"

        it "File 1"{
            Get-Content "$env:TEMP\FCLogTest01.log" | Should Be "Testing"
            }
        it "File 2"{
            Get-Content "$env:TEMP\FCLogTest02.log" | Should Be "Testing"
            }
        }
Context 'Create Folder if it does not exist'{
        $file1 = "$env:TEMP\FCTests\FCNewFolder\FCLogTest01.log"
        $file2 = "$env:TEMP\FCTests\FCNewFolder\ANotherNewFolder\FCLogTest02.log"
        $filePath = $file1,$file2
        Remove-Item $filePath -Force -ErrorAction Ignore | Out-Null
        Set-logTargets -File $filePath -Console 0
        Write-Log "Testing"

        it "File 1"{
            Get-Content $file1 | Should Be "Testing"
            }
        it "File 2"{
            Get-Content $file2 | Should Be "Testing"
            }
        }

Context 'Multiple messages'{
        $file1 = "$env:TEMP\FCLogTest01.log"
        $file2 = "$env:TEMP\FCLogTest02.log"
        $filePath = $file1,$file2
        Remove-Item $filePath -Force -ErrorAction Ignore | Out-Null
        Set-logTargets -File $filePath -Console 0
        "test1","test2" | Write-Log

        it "File 1"{
            Get-Content $file1 | Should Be "test1","test2"
            }
        it "File 2"{
            Get-Content $file2 | Should Be "test1","test2"
            }
        }
}

Describe 'Set-LogLevel'{
    COntext 'Valid input'{
        it 'Debug'{
            Set-LogLevel Debug
            Write-Log "Debug Test" Debug | Should -be "Debug Test"
        }
    }
}