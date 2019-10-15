function Get-TFSWIQLQueryResults{
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
,[string] $query)


$outputObj = New-Object PSObject
$outputObj | Add-Member -Type NoteProperty -Name repository -Value $pipelineInput.Repository
$repositoryID = $pipelineInput.repository.id

if ([String]::IsNullOrEmpty($query)){
    Write-Log "Please pass a query" Error -ErrorAction Stop
}
$BaseTFSURL = Get-TFSRestURL
$action = "/_apis/wit/wiql?api-version=$($script:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$requestBody = @"
{
  "query": "$query"
}
"@
$queryOut = New-Object PSObject
$queryOut | Add-Member -type NoteProperty -Name QueryText -Value $query
$queryOut | Add-Member -type NoteProperty -Name QueryResult -Value $null
$response = Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method POST -Body $requestBody -ContentType "application/json" -Headers $script:AuthHeader
$queryOut.QueryResult = $response
if ([bool]($outputObj.PSobject.Properties.name -match "QueryResults")){
    $outputObj.QueryResults += $queryOut
}
else{
    $outputObj | Add-Member -type NoteProperty -Name "QueryResults" -value @()
    $outputObj.QueryResults += $queryOut
}

Write-Output $outputObj
} Export-ModuleMember -Function Get-TFSWIQLQueryResults
