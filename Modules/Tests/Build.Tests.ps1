$here = Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -Parent
Describe 'Script code is valid'{
    Write-Verbose "looking: $here"
    $files = (Get-ChildItem $here -Recurse -Include "*.psm1","*.ps1"  )
    Context 'Validate script code'{
    foreach ($file in $files ){
        $fileName = $file.Name

        it "$fileName"{
            $psFile = Get-Content -Path $file.FullName -ErrorAction Stop

            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile,[ref]$errors)
            $errrors.Count | Should Be 0
            }
        }
    }
}