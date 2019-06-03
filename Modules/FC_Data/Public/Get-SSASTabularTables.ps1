function Get-SSASTabularTables{
param(
[Parameter(ValueFromPipeline,position=0)][Microsoft.AnalysisServices.Tabular.Database]$Database
,[string[]]$name = $null)

try{
    Write-Log "loading Microsoft.AnalysisServices assemblies that we need" Debug
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Core") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Tabular") | Out-Null
}
catch{
    Write-Log "Could not load the needed assemblies... TODO: Figure out and document how to install the needed assemblies. (I would start with the SQL feature pack)" Error -ErrorAction Stop
}


    $out = $Database.Model.Tables| where { $_.name -in $(if ($name -eq $null){$_.name}else{$name})}

Write-Output  $out
} Export-ModuleMember -function Get-SSASTabularTables