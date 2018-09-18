Function Get-GitBranchesWithChange{
param([string] $filePath)

$oldLocation = Get-Location
try{
    Set-Location (Split-Path $filePath)
    $lastMasterCommit = Get-GitLastCommit -path $filePath -masterBranch
    $a = get-location
    git for-each-ref --format="%(refname:short)" refs/heads | where {$_ -ne "master"}
    $x = 0
}
catch{
    Set-Location $oldLocation
}
Set-Location $oldLocation
}Export-ModuleMember -Function Get-GitBranchesWithChange