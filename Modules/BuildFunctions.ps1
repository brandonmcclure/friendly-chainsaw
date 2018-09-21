function Update-ManifestFromConfig {
  param($ManifestConfigPath,$ManifestPath,$moduleName)
  Write-Host "Loading configuration data from $ManifestConfigPath"
  $configData = Get-Content $ManifestConfigPath | ConvertFrom-Json
  if (Test-Path $ManifestPath) {
    Write-Host "Manifest already exists"
    if (![string]::IsNullOrEmpty($configData.Author)) {
      Update-ModuleManifest -Path $ManifestPath -Author $configData.Author
    }
    if (![string]::IsNullOrEmpty($configData.Description)) {
      Update-ModuleManifest -Path $ManifestPath -Description $configData.Description
    }
    if (![string]::IsNullOrEmpty($moduleName)) {
      Update-ModuleManifest -Path $ManifestPath -RootModule "$moduleName.psm1"
    }
    if (![string]::IsNullOrEmpty($configData.PSVersion)) {
      Update-ModuleManifest -Path $ManifestPath -PowerShellVersion $configData.PSVersion
    }
  }
  else {
    New-ModuleManifest -Path $ManifestPath -Author $configData.Author -Description $configData.Description -RootModule $moduleName -ModuleVersion "1.0" -PowerShellVersion $configData.PSVersion -RequiredModules $configData.requiredModules -NestedModules $configData.nestedModules | Out-Null
  }
  Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
  Write-Host "Module manifest creation/testing complete"
}

function Invoke-ScriptAnalyserWithReport {
  param($moduleDir)
  $events = Invoke-ScriptAnalyzer $moduleDir -Recurse

  #Create the HTML table without alternating rows, colorize Warning and Error messages, highlighting the whole row.
  $eventTable = $events | sort -Descending -Property Severity,ScriptName | New-HTMLTable -setAlternating $false |
  Add-HTMLTableColor -Argument "Warning" -Column "Severity" -AttrValue "background-color:orange;" -WholeRow |
  Add-HTMLTableColor -Argument "Error" -Column "Severity" -AttrValue "background-color:red;" -WholeRow #|        Add-HTMLTableColor -Argument "Error" -Column "EntryType" -AttrValue "background-color:#FFCC99;" -WholeRow

  $reportPath = "$moduleDir\ScriptAnalyserResults - $(Split-Path $moduleDir -Leaf).htm"
  $HTML = New-HTMLHead
  $HTML += "<h3>ScriptAnalyserResults - $(Split-Path $moduleDir -Leaf) $(Get-Date -Format "yyyy.MM.dd_HH.mm.ss")</h3>"
  $HTML += $eventTable | Close-HTML

  #test it out
  Set-Content "$reportPath" $HTML
  & 'C:\Program Files\Internet Explorer\iexplore.exe' "$reportPath"
}
