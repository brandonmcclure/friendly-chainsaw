﻿function New-GitTrackThisBranchForAutoIntegration{
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
param([string] $configFilePath = "$env:USERPROFILE\friendly chainsaw\GitAutoIntegration.json",
[string] $intoBranchName)

if (!(Test-Path)){
    New-Item (Split-Path $configFilePath -parent) -ItemType Directory -Force -ErrorAction Ignore
    New-Item $configFilePath -ItemType File -Force -ErrorAction Ignore
}
$currentBranch = Get-GitBranch
Write-Log "Configuring branch $currentBranch to merge into $intoBranch"

$jsonContent = Get-Content -Path $configFilePath | ConvertFrom-Json

} Export-ModuleMember -Function  New-GitTrackThisBranchForAutoIntegration