function New-TFSPullRequestComment{
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
,[string] $PRDescription
,[string] $User
,[string] $Vote
)

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
$outputObj = $pipelineInput

switch ($Vote){
    "Approved"{$tfsVote = 10}
    "Rejected"{$tfsVote = 0}
    default{$tfsVote = 0}
}
$requestBody = ''
#ehstfsrest - fbf7c924-979e-4101-bfda-5f4fe5f70467
#bmcclure - 835a4796-e8df-48f0-bd89-4321fd5f9fb0
$requestBody = @"
{"reviewers":[{
   "id":"fbf7c924-979e-4101-bfda-5f4fe5f70467",
   "vote":"$tfsVote"  
   }
   ]
}
"@
$BaseTFSURL = Get-TFSRestURL
$action = "/git/repositories/$($repositoryID)/pullrequests/$($pullRequestID)/threads?api-version=$($script:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$response = (Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Patch -Body $requestBody -ContentType "application/json").value

if (![string]::IsNullOrEmpty($projectName)){
    $response = $response | Where {(Split-Path $_.sourceRefName -Leaf) -eq $projectName}
}

Write-Output $outputObj
} Export-ModuleMember -Function New-TFSPullRequestComment