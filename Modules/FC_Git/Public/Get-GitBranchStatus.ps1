function Get-GitBranchStatus {
    param([string] $sourceBranchName = 'master',[string]$targetBranch = $null,[switch] $full)
    if([string]::IsNullOrEmpty($targetBranch)){
        $targetBranch = FC_Git\Get-GitBranch
    }
    $behindOptions = "rev-list --left-only --count $sourceBranchName...$targetBranch"
    $aheadOptions = "rev-list --right-only --count $sourceBranchName...$targetBranch"
    $behind = Start-MyProcess "git" $behindOptions -sleepTimer 0
    $ahead = Start-MyProcess "git" $aheadOptions -sleepTimer 0

    $outObj = New-Object psobject
    $outObj | Add-Member -type NoteProperty -Name sourceBranch -Value $sourceBranchName
    $outObj | Add-Member -type NoteProperty -Name targetBranch -Value $targetBranch
    $behind.stdout -match "(?ms).?(\d).?" | Out-Null
    $outObj | Add-Member -type NoteProperty -Name Behind -Value $matches[1]
    $ahead.stdout -match "(?ms).?(\d).?" | Out-Null
    $outObj | Add-Member -type NoteProperty -Name Ahead -Value $matches[1]

    if ($full){
        Write-Output $outObj
    }
    else{
        Write-Output "$targetBranch branch is $($outObj.Behind) and $($outObj.Ahead) compared to $sourceBranchName"
    }

} Export-ModuleMember -Function Get-GitBranchStatus
