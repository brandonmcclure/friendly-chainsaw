Remove-Module FC_Git -Force -ErrorAction Ignore | Out-Null
Import-Module FC_Git -Force

Describe "Sync-GitRepo"{
    Context "Parameter Validation"{
        $testRepoPath = "$($TestDrive):\source\test"
        $testBranchName = 'master'
        It "Null Inputs throws error"{
            $scriptBlock = {Sync-GitRepo -ErrorAction Stop }
            $scriptBlock | Should throw "Parameter set cannot be resolved using the specified named parameters."
        }
        It "Not on master, fails when checking master out"{
        $returnVal = {stderr="This is an error"
            stdout="stdout"
             exitCode=0}
             mock Set-Location {}
             mock -ModuleName FC_Git Get-GitBranch {return "Notmaster"}
            mock -ModuleName FC_Git Start-MyProcess {return $returnVal} -Verifiable
           Sync-GitRepo -repoPath $testRepoPath -ErrorAction Stop
           Assert-MockCalled -ModuleName FC_Core Start-MyProcess -Times 1
        }
    }
}