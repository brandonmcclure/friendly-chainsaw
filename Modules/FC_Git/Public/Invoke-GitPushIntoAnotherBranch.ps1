function Invoke-GitPushIntoAnotherBranch{
<#
    .Synopsis
      Please give your script a brief Synopsis,
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       What sort of pipeline inputdoes this expect?
    .OUTPUTS
       What sort of pipeline output does this output?
    .LINK
       www.google.com
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string] $autoRepoPath
,[string] $intoBranchName = $null)

if ([String]::IsNullOrEmpty($intoBranchName)){
    Write-Log "Please pass a intoBranchName" Error -ErrorAction Stop
}
if (!(Test-Path $autoRepoPath)){
    Write-Log "$autoRepoPath is not a valid path" Error -ErrorAction Stop
}

$currentLocation = Get-Location
$currentBranch = Get-GitBranch

if ([String]::IsNullOrEmpty($currentBranch)){
    Write-Log "Could not get the current branch name. Aborting" Error -ErrorAction Stop
}

try{
    Set-Location $autoRepoPath
    git checkout $currentBranch
    git pull
    git checkout $intoBranchName
    git pull
    git merge $currentBranch
    git push
    git checkout master
    git pull
    

}
catch{
throw

}
finally{
    Set-Location $currentLocation
}
} Export-ModuleMember -Function Invoke-GitPushIntoAnotherBranch