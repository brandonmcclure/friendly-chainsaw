Function Close-CrystalReport{
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
param([Parameter(ValueFromPipeline,position=0)][CrystalDecisions.CrystalReports.Engine.ReportDocument]  $report =$null)

if ($report -eq $null){
    Write-Log "Please pass a crystal report into the function" Error -ErrorAction Stop
}
Write-Log "Saving the report to: $($report.FilePath)" Debug
$report.SaveAs($report.FilePath)
Write-Log "Disposing of the report object" Debug
$report.Dispose()


}Export-ModuleMember -Function Close-CrystalReport