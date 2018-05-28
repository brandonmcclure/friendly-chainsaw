function Get-MyOneDriveFiles{
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
param([Parameter(ValueFromPipeline)] $pipelineInput)

$BaseURL = Get-MSGraphRestURL
$action = "/me/drive/root/children" 
$fullURL = $BaseURL + $action
$authHeader = @{
   'Content-Type'='application\json'

   'Authorization'=$script:msGraphToken

}

Write-Log "URL we are calling: $fullURL" Debug

$response = Invoke-RestMethod -uri $fullURL -Method Get -Headers $authHeader #| Select -ExpandProperty Value
if ([string]::IsNullOrEmpty($repositoryName)){
}
else{
    $response = ($response | Where {$_.name -eq $repositoryName})
}

} Export-ModuleMember -Function Get-MyOneDriveFiles