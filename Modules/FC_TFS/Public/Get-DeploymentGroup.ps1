function Get-DeploymentGroup{
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
       https://docs.microsoft.com/en-us/azure/devops/integrate/previous-apis/work/iterations?view=tfs-2018
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Verbose","Info","Warning","Error", "Disable")][string] $logLevel = "Debug"
,  [Parameter(position = 0)] [int]$DeploymentGroupId = $env:DEPLOYMENTGROUPID
,[string] $PAT
)

Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  $currentLogLevel = Get-LogLevel

try{
if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel

$BaseTFSURL = Get-TFSRestURL
if ([string]::IsNullOrEmpty($BaseTFSURL)){
    Write-Log "Could not get the Base TFS URL. Ensure that you have called Set-TFSBaseURL, Set-TFSCollection and Set-TFSProject" Error -ErrorAction Stop
}

    $action = "/_apis/distributedtask/deploymentgroups/$DeploymentGroupId/targets?api-version=$($script:apiVersion)" 
    
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$response = Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json" -Headers $script:AuthHeader -ErrorAction Stop

Write-Output $response.value
}
catch{
      Set-LogLevel $currentLogLevel
      throw
}
} Export-ModuleMember -Function Get-DeploymentGroup