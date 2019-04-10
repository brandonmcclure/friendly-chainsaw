function Get-GitAllBranchStatus {
    param([string] $sourceBranchName = 'master',[string]$targetBranch = $null,[switch] $full)
    $branches = Get-GitBranch -returnAllBranches

    Write-Log "Checking each branch status" Warning
    $outCollection = @()
    foreach($branch in $branches){
        if ($sourceBranchName -in $branch -or [string]::IsNullOrEmpty($branch)){
            continue
        }
        $result = Get-GitBranchStatus -sourceBranchName $sourceBranchName -targetBranch $branch -full
        $outObj = New-Object PSObject
        $outObj | Add-member -type NoteProperty -Name branch -Value $branch
        $outObj | Add-member -type NoteProperty -Name behindAahead -Value "$($result.Behind) | $($result.Ahead)"
        $outCollection+= $outObj
    }

    Write-Output $outCollection

} Export-ModuleMember -Function Get-GitAllBranchStatus
