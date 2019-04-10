<#
    .Synopsis
     Runs all or some Pester tests
    .EXAMPLE
        Run only 1 .tests file

        TestRunner -paths "DataAccess.Tests.ps1"
    .EXAMPLE
        Run 2 .tests file

        TestRunner -paths @("DataAccess.Tests.ps1","Build.Tests.ps1")
    .EXAMPLE
        Run All .tests files (will look in the $PSCommandPath parent directory)

        TestRunner
    .EXAMPLE
        Run only a single Describe block. The -paths is optional, but saves time. Instead of searching for all .test files, then the specific describe, it goes right to the correct test

        TestRunner -paths "DataAccess.Tests.ps1" -describesToFilter "Process-AllTabularModel"
    .EXAMPLE
        Run only 2 Describe blocks. The -paths is optional, but saves time. Instead of searching for all .test files, then the specific describe, it goes right to the correct test

        TestRunner -paths "DataAccess.Tests.ps1" -describesToFilter @("Process-AllTabularModel","Invoke-MockableDateCompare")
   
    #>
param([string[]]$paths = @("FC_TFS.Tests.ps1"), [string[]] $describesToFilter = @())
clear
Remove-Module Pester -Force -ErrorAction Ignore | Out-Null
Import-Module Pester -Force
$rootDir = Split-Path $PSCommandPath -Parent
$paths = $(if ([string]::IsNullOrEmpty($paths)){$rootDir}else{$paths|foreach {"$rootDir\$_"}})

Write-Host "Running tests from: $paths"
foreach($path in $paths){
    if([string]::IsNullOrEmpty($describesToFilter)){
        Invoke-Pester "$path" -Verbose
    }
    else{
        Invoke-Pester "$path" -Verbose -TestName $describesToFilter
    }
}