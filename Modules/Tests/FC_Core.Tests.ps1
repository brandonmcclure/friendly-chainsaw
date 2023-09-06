
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
