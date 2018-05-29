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
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug"
,[switch] $winEventLog
,[Parameter(ValueFromPipeline)] $pipelineInput)

Import-Module FC_Log, FC_MicrosoftGraph,MSAL.PowerShell -Force

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog

if (!([string]::IsNullOrEmpty($pipelineInput))){
    Write-Log "Parse the pipeline object here" Debug
    
}

Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug
$script:msGraphToken = Get-MSALToken -Scopes "Notes.Read" -ClientId "00d16af4-d0c7-460a-a9dc-fd350eb4b100" -RedirectUri "urn:ietf:wg:oauth:2.0:oob" | Select -ExpandProperty IdToken
Write-log "accessToken: $script:msGraphToken"
Get-MyOneDriveFiles
Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug