function Get-TFSReleases{
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
param([int] $ReleaseID)


$BaseTFSURL = Get-TFSRestURL
$action = "/_apis/release/releases?searchText=Release&api-version=$($script:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$response = (Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json" -Headers $script:AuthHeader).value
if ([string]::IsNullOrEmpty($repositoryName)){
}
else{
    $response = ($response | Where {$_.name -eq $repositoryName})
}

$outputObj = New-Object PSObject
$outputObj | Add-Member -Type NoteProperty -Name repository -Value $response

Write-Output $outputObj
} Export-ModuleMember -Function Get-TFSReleases