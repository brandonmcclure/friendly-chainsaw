function Get-TFSPullRequests{
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
param([Parameter(ValueFromPipeline)] $pipelineInput
,[string] $sourceRefName
,[string] $targetRefName)


$outputObj = New-Object PSObject
$outputObj | Add-Member -Type NoteProperty -Name repository -Value $pipelineInput.Repository
$repositoryID = $pipelineInput.repository.id

if ([String]::IsNullOrEmpty($repositoryID)){
    Write-Log "Please pass a repositoryID" Error -ErrorAction Stop
}
$BaseTFSURL = Get-TFSRestURL
$action = "/git/repositories/$repositoryID/PullRequests?api-version=$($Global:apiVersion)&name=$($BuildName)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$response = (Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json-patch+json").value

if (![string]::IsNullOrEmpty($sourceRefName)){
    $response = $response | Where {(Split-Path $_.sourceRefName -Leaf) -eq $sourceRefName}
}
if (![string]::IsNullOrEmpty($targetRefName)){
    $response = $response | Where {(Split-Path $_.targetRefName -Leaf) -eq $targetRefName}
}
$outputObj | Add-Member -Type NoteProperty -Name PullRequests -Value $response
Write-Output $outputObj
} Export-ModuleMember -Function Get-TFSPullRequests