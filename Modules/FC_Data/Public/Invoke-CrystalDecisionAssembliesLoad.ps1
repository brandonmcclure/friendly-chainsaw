Function Invoke-CrystalDecisionAssembliesLoad{
try{
    Write-Log "loading CrystalDecisions assemblies that we need" Debug
[System.Reflection.Assembly]::LoadWithPartialName("CrystalDecisions.CrystalReports.Engine") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("CrystalDecisions.Shared") | Out-Null
}
catch{
    Write-Log "Could not load the needed assemblies... TODO: Figure out and document how to install the needed assemblies. (I would start with the SQL feature pack)" Error -ErrorAction Stop
}
}Export-ModuleMember -Function Invoke-CrystalDecisionAssembliesLoad