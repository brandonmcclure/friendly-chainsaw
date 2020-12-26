$here = Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -Parent
Write-Verbose "looking: $here"
$Instances = Get-ChildItem $here -Recurse -Include "*.psm1","*.ps1"  

# Create an empty array
$TestCases = @()

# Fill the Testcases with the values and a Name of Instance
$Instances.ForEach{$TestCases += @{File = $_}}

Describe 'Script code is valid'{
   
    Context 'Validate script code'{
         it "Files are proper PS" -TestCases $TestCases{
            param($file)
            $psFile = Get-Content -Path $file.FullName -ErrorAction Stop

            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile,[ref]$errors)
            $errrors.Count | Should -Be 0
            }
        }
}