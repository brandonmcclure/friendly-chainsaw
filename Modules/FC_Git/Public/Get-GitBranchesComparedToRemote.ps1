Function Get-GitBranchesComparedToRemote{
<#
    .Synopsis
      WIP, this script is going to check the status of all your local branches and compare it with the origin (TFS server) to see which local branches are out of sync (and by how much) with the origi
    .PARAMETER
        branchName
       if specified, only check the status of this branch. If left as the default, it will compare all branches
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string] $branchName = $null
,[string] $remoteName = "origin")

Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

if ([string]::IsNullOrEmpty($branchName)){
    $branches = git branch
}
else{
    $branches = $branchName
    
}
$branchesToDelete = Get-GitBranchesToDelete
$outputs = @()

foreach ($branch in $branches){
    
    $branchName = $($($branch.Replace(' ','')).Replace('*',''))
    $output = New-Object -TypeName PSObject
    $output | Add-Member –MemberType NoteProperty –Name branchName –Value $branchName
    $result = git branch -r 
    if (!($result -like "*$branchName*")){
        $output | Add-Member –MemberType NoteProperty –Name hasUpstream –Value $false
        Write-Log "Could not find a branch named $branchName in your remote ref list. Perhaps the branch has not been pushed up to the remote?" Debug
    }
    else {
        $result = $null
        $output | Add-Member –MemberType NoteProperty –Name hasUpstream –Value $true

        if ($branchName -in $branchesToDelete){
            $output | Add-Member –MemberType NoteProperty –Name upstreamRefValid –Value $false
        }
        else{
            $output | Add-Member –MemberType NoteProperty –Name upstreamRefValid –Value $true
        }
        
        Write-log "git rev-list $remoteName/master..$remoteName/$branchName" Debug
        $result = git rev-list $remoteName/master..$remoteName/$branchName
        $output | Add-Member –MemberType NoteProperty –Name aheadRemoteMaster –Value $($result.count)
        Write-Log "Remote branch named '$branchName' is: $($result.count) ahead of remote master" Debug
        $result = $null
        Write-Log "git rev-list $remoteName/$branchName...$remoteName/master" Debug
        $result = git rev-list $remoteName/$branchName...$remoteName/master
        $output | Add-Member –MemberType NoteProperty –Name behindRemoteMaster –Value $($result.count)
        Write-Log "Remote branch named '$branchName' is: $($result.count) behind remote master" Debug
        Write-Log "*******" Debug
        Write-log "git rev-list heads/$branchName...$remoteName/$branchName" Debug
        $result = git rev-list heads/$branchName...$remoteName/$branchName
        $output | Add-Member –MemberType NoteProperty –Name aheadRemote –Value $($result.count)
        Write-Log "Local branch named '$branchName' is: $($result.count) ahead of remote" Debug
        $result = $null
        Write-Log "git rev-list $remoteName/$branchName...heads/$branchName" Debug
        $result = git rev-list $remoteName/$branchName...heads/$branchName
        $output | Add-Member –MemberType NoteProperty –Name behindRemote –Value $($result.count)
        Write-Log "Local branch named '$branchName' is: $($result.count) behind remote" Debug

        $outputs += $output
    }  
}

$outputs
}export-modulemember -Function Get-GitBranchesComparedToRemote