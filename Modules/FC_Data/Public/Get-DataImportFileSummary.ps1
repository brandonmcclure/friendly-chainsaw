function get-DataImportFileSummary{
       <# 
.SYNOPSIS 
    Use this to get an object of type DataImportFileSummary. This method does not require you to have a "using" statement in your calling scripts
.OUTPUTS 
    [DataImportFileSummary]
#>
Write-Output $(New-Object DataImportFileSummary)
}Export-ModuleMember -function Get-DataImportFileSummary