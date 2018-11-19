function New-GitTrackThisBranchForAutoIntegration{
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
param([string] $configFilePath = "$env:TEMP\friendly chainsaw\GitAutoIntegration.json",
[string] $intoBranchName)

if ([string]::IsNullOrEmpty($repoPath) -and [string]::IsNullOrEmpty($repoName)){
    Write-Log "please pass either the -repoPath or repoName parameters" Error
}
elseif([string]::IsNullOrEmpty($repoPath)){
    Write-Log "Please pass a valid repo path to $repoPath" Error -ErrorAction Stop
}

if (!(Test-Path)){
    New-Item (Split-Path $configFilePath -parent) -ItemType Directory -Force -ErrorAction Ignore
    New-Item $configFilePath -ItemType File -Force -ErrorAction Ignore
}
$currentBranch = Get-GitBranch
Write-Log "Configuring branch $currentBranch to merge into $intoBranch"

$jsonContent = Get-Content -Path $configFilePath | ConvertFrom-Json

} Export-ModuleMember -Function  New-GitTrackThisBranchForAutoIntegration