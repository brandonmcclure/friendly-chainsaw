function Export-CRMetadata {
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
  param([Parameter(Position = 1)][ValidateSet("Debug","Info","Warning","Error","Disable")] [string]$logLevel = "Info"
    ,[switch]$winEventLog
    ,[Parameter(ValueFromPipeline,Position = 0)] $CRInputObject)

  if ([string]::IsNullOrEmpty($logLevel)) { $logLevel = "Info" }
  Set-LogLevel $logLevel
  Set-logTargetWinEvent $winEventLog

  $report = $CRInputObject.report
  $output = New-Object psobject
  $output | Add-Member -Type NoteProperty -Name report -Value $report
  $report.SummaryInfo
  #$output | Add-Member -type NoteProperty -name report -Value $report.report

  Write-Output $output

} Export-ModuleMember -Function Export-CRMetadata
