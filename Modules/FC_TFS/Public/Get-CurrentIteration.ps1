Function Get-CurrentIteration{
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
,$type = 'Bug')

$repositoryID = $pipelineInput.repository.id
if ([String]::IsNullOrEmpty($repositoryID)){
    Write-Log "Please pass a repositoryID" Error -ErrorAction Stop
}
$BaseTFSURL = Get-TFSRestURL_Team -teamName 'Cogito%20-%20CPM'
$action = '/work/TeamSettings/Iterations?$timeframe=current&api-version='+$($script:apiVersion) 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Verbose


$outputObj = New-Object PSObject
$outputObj | Add-Member -Type NoteProperty -Name repository -Value $pipelineInput.Repository
Clear-Variable response -ErrorAction Ignore | Out-Null
try{
$response = Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json-patch+json" 
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
     }
if ([bool]($outputObj.PSobject.Properties.name -match "CurrentIteration")){
    $outputObj.CurrentIteration += $response.value | select id,name,path
}
else{
    $outputObj | Add-Member -type NoteProperty -Name "CurrentIteration" -value @()
    $outputObj.CurrentIteration += $response.value | select id,name,path
}
Write-Output $outputObj
$x = 0;
}Export-ModuleMember -Function Get-CurrentIteration