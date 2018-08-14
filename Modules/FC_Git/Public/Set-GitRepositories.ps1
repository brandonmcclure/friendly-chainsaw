function Set-GitRepositories{
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
param([Parameter(ValueFromPipeline)][string] $localRepoPath
,[string] $repoName = $null)

if ([String]::IsNullOrEmpty($localRepoPath)){
    Write-Log "Please pass a localAutoRepoPath" Error -ErrorAction Stop
}
if (!(Test-Path $localRepoPath)){
    Write-Log "$localRepoPath is not a valid path" Error -ErrorAction Stop
}
if ([string]::IsNullOrEmpty($repoName)){
    $repoName = Split-Path $localRepoPath -Leaf
}
#Check if the array has anything in it. If so, check that the name property is unique.
if (!($Global:GitRepositories.Count -eq 0) ){
    if ($Global:GitRepositories.name.Contains($repoName) ){
        Write-Log "$repoName repo is already stored" Warning
        return
    }
}

$repoObj = New-Object -TypeName PSObject
$repoObj | Add-Member -Type NoteProperty -Name name -Value $repoName
$repoObj | Add-Member -Type NoteProperty -Name path -Value $localRepoPath
$Global:GitRepositories += $repoObj
} Export-ModuleMember -Function Set-GitRepositories