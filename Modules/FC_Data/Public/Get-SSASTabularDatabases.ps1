function Get-SSASTabularDatabases{
param($serverName)

try{
    Write-Log "loading Microsoft.AnalysisServices assemblies that we need" Debug
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Core") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Tabular") | Out-Null
}
catch{
    Write-Log "Could not load the needed assemblies... TODO: Figure out and document how to install the needed assemblies. (I would start with the SQL feature pack)" Error -ErrorAction Stop
}

$server = New-Object Microsoft.AnalysisServices.Tabular.Server
$server.Connect($serverName)

Write-Output $server.Databases
} Export-ModuleMember -function Get-SSASTabularDatabases