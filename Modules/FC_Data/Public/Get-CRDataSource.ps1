function Get-CRDataSource{
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
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info"
,[switch] $winEventLog
,[Parameter(ValueFromPipeline)] $pipelineInput)

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog

if (!([string]::IsNullOrEmpty($pipelineInput))){
    Write-Log "Parse the pipeline object here" Debug
    
}

Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug

Write-Log "Do stuff here"

Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
}Export-ModuleMember -Function Get-CRDataSource