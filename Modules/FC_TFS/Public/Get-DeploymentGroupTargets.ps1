function Get-DeploymentGroupTargets{
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


$response = Get-DeploymentGroup -DeploymentGroupId $DeploymentGroupId -PAT $PAT

$BaseTFSURL = Get-TFSRestURL
$targets = @()
foreach ($target in $response)
{
  $targetObj = New-Object psobject
  $targetObj | Add-Member -Type NoteProperty -Name id -Value $target.Id

  $fullURL = "$BaseTFSURL/_apis/distributedtask/deploymentgroups/$DeploymentGroupId/targets/$($targetObj.id)?api-version=$($script:apiVersion)"
  Write-Log "uri for rest call: $fullURL" Debug
  $results = Invoke-RestMethod -Method Get -ContentType "application/json-patch+json" -Uri $fullURL -Headers $script:AuthHeader -ErrorAction Stop

  $targets += $results
}

Write-Output $targets
}
catch{
      Set-LogLevel $currentLogLevel
      throw
}
finally{
    Set-LogLevel $currentLogLevel
}
} Export-ModuleMember -Function Get-DeploymentGroupTargets