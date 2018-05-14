function Abandon-TFSPullRequest{
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

$repositoryID = $pipelineInput.repository.id
$repositoryName = $pipelineInput.repository.Name
$pullRequestID = $pipelineInput.PullRequests.PullRequestID
$projectID = $pipelineInput.repository.project.id


if ([String]::IsNullOrEmpty($repositoryID)){
    Write-Log "Please pass a repositoryID" Error
    return
}
if ([String]::IsNullOrEmpty($pullRequestID)){
    Write-Log "Please pass a pullRequestID" Error
    return
}
$BaseTFSURL = Get-TFSRestURL
$action = "/git/repositories/$($repositoryID)/pullrequests/$($pullRequestID)?api-version=$($script:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug

   
$requestBody = @"
{
  "status":"abandoned"
}
"@
try{
$response = Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Patch -Body $requestBody -ContentType "application/json"
}
catch{
    $ex = $_.Exception
    $errResponse = $ex.Response.GetResponseStream()
    $ex.Response
    $_.InnerException
    $reader = New-Object System.IO.StreamReader($errResponse) 
     $reader.BaseStream.Position = 0 
     $reader.DiscardBufferedData() 
     $responseBody = $reader.ReadToEnd(); 
     $responseBody.Response 

    $line = $_.InvocationInfo.ScriptLineNumber
    $scriptName = Split-Path $_.InvocationInfo.ScriptName -Leaf
    $msg = $ex.Message
    Write-Log "Error in script $scriptName at line $line, error message: $msg" Warning
}
write-Output $response.Value

} Export-ModuleMember -Function Abandon-TFSPullRequest