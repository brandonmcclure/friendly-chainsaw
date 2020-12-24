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
            $scriptBlock | Should -throw "Parameter set cannot be resolved using the specified named parameters."
        }
        It "Not on master, fails when checking master out"{
             mock Set-Location {}
             mock -ModuleName FC_Git Get-GitBranch {return "Notmaster"}
            mock -ModuleName FC_Git Start-MyProcess -ParameterFilter {$EXEPath -eq 'git' -and $options -eq "checkout $script:testBranchName"} {[PSCustomObject]@{exitCode = '0'
stderr = "Error checking out $script:testBranchName"
stdout = "Error checking out $script:testBranchName"
}} -Verifiable
           $scriptBlock = {Sync-GitRepo -repoPath $testRepoPath -branchName $script:testBranchName -ErrorAction Stop }
           $scriptBlock | Should -throw "     [HandleSTdOut<Process>] There was an error: Error checking out "
           Assert-MockCalled -ModuleName FC_Git Start-MyProcess -Exactly 1
        }
    }
}

Describe "Get-GitLastCommit"{
    Context "Parameter Validation"{
        BeforeAll{
            $repoPath = "C:\temp\gitRepo"
            Remove-Item $repoPath -recurse -force -ErrorAction SilentlyContinue | Out-Null
            New-Item $repoPath -itemType directory

            $dir1 = "$repoPath\dir1"
            New-Item $dir1 -itemType directory

            Set-Location $repoPath
            git init 
            "test" | Set-Content file1.txt
            git add . 
            git commit -m "first commit"

            Set-Location $dir1
            git init 
            "test" | Set-Content file1.txt
            git add . 
            git commit -m "first commit"
        }
        it "Gets Commit From Current Directory"{
            Set-Location $repoPath
            Get-GitLastCommit | Should -Not -BeNullOrEmpty 
        }
        it "Gets Commit From Current Directory -masterbranch"{
            Set-Location $repoPath
            Get-GitLastCommit -masterBranch| Should -Not -BeNullOrEmpty 
        }
        it "Gets Commit From specific Directory"{
            Set-Location $repoPath
            Get-GitLastCommit -path $dir1 -masterBranch| Should -Not -BeNullOrEmpty 
        }
    }
}