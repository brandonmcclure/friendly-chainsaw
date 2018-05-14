function Get-TFSProjects{
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
param([string] $projectName)

$BaseTFSURL = Get-TFSRestURL
$action = "/projecthistory?api-version=$($Global:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$response = (Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json-patch+json").value

if (![string]::IsNullOrEmpty($projectName)){
    $response = $response | Where {(Split-Path $_.sourceRefName -Leaf) -eq $projectName}
}

Write-Output $response
} Export-ModuleMember -Function Get-TFSProjects