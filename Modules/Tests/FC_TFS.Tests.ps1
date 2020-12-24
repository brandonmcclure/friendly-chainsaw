Remove-Module FC_TFS -Force -ErrorAction Ignore | Out-Null
Import-Module "$(Split-Path (Split-Path $MyInvocation.MyCommand.Path -PArent) -Parent)\FC_TFS\FC_TFS" -Force

describe 'Get-TFSRestURL_Team'{
    Context 'Parameter Validation'{
        it 'No team results in error'{
            $scriptBlock = {Get-TFSRestURL_Team}
            $scriptBlock | should throw "invalid teamName"
        }
        it 'Do not set the script variables results in $null'{
            Get-TFSRestURL_Team -teamName "TestTeam" | should be $null
        }
        it 'Only set the base URL results in $null'{
            Set-TFSBaseURL 'https://baseurl.com'
            Get-TFSRestURL_Team -teamName "TestTeam" | should be $null
            Set-TFSBaseURL $null
        }
        it 'Only set the TFS collection results in $null'{
            Set-TFSCollection 'TestCollection'
            Get-TFSRestURL_Team -teamName "TestTeam" | should be $null
            Set-TFSCollection $null
        }
        it 'Only set the project results in $null'{
            Set-TFSProject 'TestProject'
            Get-TFSRestURL_Team -teamName "TestTeam" | should be $null
            Set-TFSProject $null
        }
    }
    context 'Valid Parameters'{
        it 'Valid setup returns valid team URL'{
            Set-TFSBaseURL 'https://baseurl.com'
            Set-TFSCollection 'TestCollection'
            Set-TFSProject 'TestProject'
            Get-TFSRestURL_Team -teamName "TestTeam" | should be 'https://baseurl.com/TestCollection/TestProject/TestTeam'
        }
    }
}
describe 'Get-TFSIterations' {
BeforeEach{
    Remove-Module FC_TFS -Force | Out-Null
    Import-Module FC_TFS -Force -DisableNameChecking
}
Context 'Parameter Validation'{
        It 'Did not perform setup will result in error'{
            $scriptBlock = {Get-TFSIterations -teamName 'TestTeam' -ErrorAction Stop}
            $scriptBlock | should throw "Could not get the Base TFS URL. Ensure that you have called Set-TFSBaseURL, Set-TFSCollection and Set-TFSProject"
        }
    }
}

describe 'ErrorAction'{
    context 'Testing different methods'{
        it 'Write-Log using local module'{
            $scriptBlock = {Write-Log "Error" Error -ErrorAction Stop}
            $scriptBlock | should throw
        }
        it 'throw'{
            $scriptBlock = {throw "sdgaag"}
            $scriptBlock | should throw
        }
        it 'Write-Error'{
            $scriptBlock = {Write-Error "asgag" -ErrorAction Stop}
            $scriptBlock | should throw
        }
    }
}