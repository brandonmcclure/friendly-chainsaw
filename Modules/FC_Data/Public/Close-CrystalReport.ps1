Function Close-CrystalReport{
<#
    .Synopsis
      Saves and closes a Crystal Report object. Use Open-CrystalReport to create a Crystal Report object from an existing .rpt file. 
    .PARAMETER report
        A crystal Report object of the type: CrystalDecisions.CrystalReports.Engine.ReportDocument. 
       
    .EXAMPLE
        Opens all .rpt files in C:\reportsFromVendor and all subdirectories, writes some sumamry info to the log, and then saves/closes the report

        Get-ChildItem C:\reportsFromVendor -recurse | where {$_.Extension -eq 'rpt'} | Open-CrystalReport | foreach {
    Write-Log "$($_.SummaryInfo.ReportTitle)" 
    Write-Log "$($_.SummaryInfo.ReportAuthor)"
    Write-Log "$($_.SummaryInfo.ReportComments)"
    Write-Log "$($_.SummaryInfo.ReportSubject)"
    Write-Output $_
    } |  Close-CrystalReport


    .INPUTS
       a Crystal Report object of the type: CrystalDecisions.CrystalReports.Engine.ReportDocument 
    .OUTPUTS
       Nothing. This should be used at the end of your Crystal Reports pipeline
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(ValueFromPipeline,position=0)] $report =$null,
[switch] $saveReport)

if ($report -eq $null){
    Write-Log "Please pass a crystal report into the function" Error -ErrorAction Stop
}

if ($saveReport){
    Write-Log "Saving the report to: $($report.FilePath)" Debug
    $report.SaveAs($report.FilePath)
}
Write-Log "Disposing of the report object" Debug
try{
$report.Dispose()
}
catch{
#Try to dispose if the report is inside of the input object. (The ouput of functions to extract/insert data) 
$report.report.Dispose()
}
}Export-ModuleMember -Function Close-CrystalReport