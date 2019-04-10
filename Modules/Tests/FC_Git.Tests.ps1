Remove-Module FC_Git -Force -ErrorAction Ignore | Out-Null
Import-Module FC_Git -Force
Remove-Module FC_Core -Force -ErrorAction Ignore | Out-Null
Import-Module FC_Core -Force

Describe "Sync-GitRepo"{
    Context "Parameter Validation"{
        $testRepoPath = "$($TestDrive):\source\test"
        $script:testBranchName = 'master'
        It "Null Inputs throws error"{
            $scriptBlock = {Sync-GitRepo -ErrorAction Stop }
            $scriptBlock | Should throw "Parameter set cannot be resolved using the specified named parameters."
        }
        It "Not on master, fails when checking master out"{
             mock Set-Location {}
             mock -ModuleName FC_Git Get-GitBranch {return "Notmaster"}
            mock -ModuleName FC_Git Start-MyProcess -ParameterFilter {$EXEPath -eq 'git' -and $options -eq "checkout $script:testBranchName"} {[PSCustomObject]@{exitCode = '0'
stderr = "Error checking out $script:testBranchName"
stdout = "Error checking out $script:testBranchName"
}} -Verifiable
           $scriptBlock = {Sync-GitRepo -repoPath $testRepoPath -branchName $script:testBranchName -ErrorAction Stop }
           $scriptBlock | Should throw "     [HandleSTdOut<Process>] There was an error: Error checking out "
           Assert-MockCalled -ModuleName FC_Git Start-MyProcess -Exactly 1
        }
    }
}