function Get-SSASTabularMeasures{
param(
[Parameter(ValueFromPipeline,position=0)][Microsoft.AnalysisServices.Tabular.Table]$Table
,[string[]]$name = $null)

try{
    Write-Log "loading Microsoft.AnalysisServices assemblies that we need" Debug
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Core") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Tabular") | Out-Null
}
catch{
    Write-Log "Could not load the needed assemblies... TODO: Figure out and document how to install the needed assemblies. (I would start with the SQL feature pack)" Error -ErrorAction Stop
}



Write-Output $table.Measures | where { $_.name -in $(if ($name -eq $null){$_.name}else{$name})}
} Export-ModuleMember -function Get-SSASTabularMeasures