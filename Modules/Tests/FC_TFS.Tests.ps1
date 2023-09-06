
describe 'Get-TFSRestURL_Team' {
	BeforeEach{
		$functionPath = Join-Path $PSScriptRoot ".functions.ps1"
		. "$functionPath"
		LoadLocalModules
		
	}
	Context 'Parameter Validation' {
		it 'No team results in error' {
			$scriptBlock = { Get-TFSRestURL_Team }
			$scriptBlock | should -throw "invalid teamName"
		}
		# it 'Do not set the script variables results in $null' {
		# 	$sb = {Get-TFSRestURL_Team -teamName "TestTeam"}
		# 	$sb | should -throw "invalid teamName"
		# }
		it 'Only set the base URL results in $null' {
			Set-TFSBaseURL 'https://baseurl.com'
			Get-TFSRestURL_Team -teamName "TestTeam" | should -be $null
			Set-TFSBaseURL $null
		}
		it 'Only set the TFS collection results in $null' {
			Set-TFSCollection 'TestCollection'
			Get-TFSRestURL_Team -teamName "TestTeam" | should -be $null
			Set-TFSCollection $null
		}
		it 'Only set the project results in $null' {
			Set-TFSProject 'TestProject'
			Get-TFSRestURL_Team -teamName "TestTeam" | should -be $null
			Set-TFSProject $null
		}
	}
	context 'Valid Parameters' {
		it 'Valid setup returns valid team URL' {
			Set-TFSBaseURL 'https://baseurl.com'
			Set-TFSCollection 'TestCollection'
			Set-TFSProject 'TestProject'
			Get-TFSRestURL_Team -teamName "TestTeam" | should -be 'https://baseurl.com/TestCollection/TestProject/TestTeam'
		}
	}
}

describe 'ErrorAction' {
	context 'Testing different methods' {
		it 'Write-Log using local module' {
			$scriptBlock = { Write-Log "Error" Error -ErrorAction Stop }
			$scriptBlock | should -throw
		}
		it 'throw' {
			$scriptBlock = { -throw "sdgaag" }
			$scriptBlock | should -throw
		}
		it 'Write-Error' {
			$scriptBlock = { Write-Error "asgag" -ErrorAction Stop }
			$scriptBlock | should -throw
		}
	}
}