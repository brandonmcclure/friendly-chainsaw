﻿Function New-TFSWorkItem{
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
,[string] $requestBody
,$type = 'Bug')

$repositoryID = $pipelineInput.repository.id
if ([String]::IsNullOrEmpty($repositoryID)){
    Write-Log "Please pass a repositoryID" Error -ErrorAction Stop
}
$BaseTFSURL = Get-TFSRestURL

$action = '/wit/workitems/$'+$type+"?api-version=$($script:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Verbose


$outputObj = New-Object PSObject
$outputObj | Add-Member -Type NoteProperty -Name repository -Value $pipelineInput.Repository


try{
$response = Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method PATCH -Body $requestBody -ContentType "application/json-patch+json" 
}
catch{
    $ex = $_.Exception
    $errResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errResponse) 
     $reader.BaseStream.Position = 0 
     $reader.DiscardBufferedData() 
     if ($logLevel -eq "Debug"){
     $responseBody = $reader.ReadToEnd(); 
     $responseBody 
     }

    $line = $_.InvocationInfo.ScriptLineNumber
    $scriptName = Split-Path $_.InvocationInfo.ScriptName -Leaf
    $msg = $ex.Message
    Write-Log "Error in script $scriptName at line $line, error message: $msg" Error -ErrorAction Stop
}

Write-Output $outputObj

}Export-ModuleMember -Function New-TFSWorkItem