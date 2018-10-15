Function Get-InstalledVoices{
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
#install new voices from: https://www.microsoft.com/en-us/download/details.aspx?id=27224
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.GetInstalledVoices() | select -ExpandProperty VoiceInfo | select Name, Age, Gender, culture, ID, Description, SupportedAudioFormats,AdditionInfo | fl

}Export-ModuleMember -Function Get-InstalledVoices