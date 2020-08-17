function Get-DataImportFile{
    <# 
.SYNOPSIS 
    Use this to get an object of type DataImportFile. This method does not require you to have a "using" statement in your calling scripts
.OUTPUTS 
    [DataImportFile]
#>
    Write-Output $(New-Object DataImportFile)
}Export-ModuleMember -Function Get-DataImportFile 