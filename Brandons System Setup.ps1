<#
    .Synopsis
      This script was initially written to setup the powershell profile on my systems at work. At some point this will be split into a more general use system setup script and and Install-FC script. Right now it makes some assumptions on how your Powershell environment works.  
    .DESCRIPTION
        This script works by modifiyng the $profile for all users, or the user running the script. I have always used this for all users, all hosts. So I am unsure how well this approach would work with indiviudal profiles. 

        
    .PARAMETER scriptPaths
        Optional
        Default: $null

        If specified, this is the location your shell will default to

    .alluserProfile
        Optional
        Defaults: true

        Sets up the all user profile. If set to false it will setup the user profile. (The user profile is not tested)
    .PARAMETER updateHelp
        Optional
        Default: false

        Adds the command "Update-Help" to the profile. Not recomended as it currently runs in the foreground. 

    .PARAMETER installGitFetchJob
        Optional
        Default: false

        Experimental. Installs a powershell scheduled job that performs a git fetch --all for all repos under a given subdirectory. Hardcoded to my folder structure ATM. 
    .PARAMETER installISEScriptSignAddOn
        Optional
        Default: false

        Adds a add-on to the powershell ISE that allows you to sign your script with one click, and an add-on to beautify your script. Highly recomended.

    .PARAMETER ModulesToImportInProfile
        Optional
        Default: @("FC_Log","FC_Git","FC_Core")	
        
        An array of modules to import as part of the profile code. These will be imported for every shell							 
    .PARAMETER quickDirectories
        Optional
        Default: $null

        A hash table of paths to make changeing my location easier.


        Run this script with a hash table of paths like this:

            -quickDirectories = @{myGit = 'C:\TFS\Misc Developer Files\Brandon McClure'}

        Then to quickly switch to that directory: 
            Set-Location $myDirs.myGit
    .PARAMETER notepadPlusPlusPath
        Optional
        Default: "C:\Program Files (x86)\Notepad++\notepad++.exe"

        If the specified path is valid, creates an alias in your profile to the exe. Alias is npp

        to open a file using the alias:

        npp path\to\file
    .PARAMETER VSCommandPrompt
        Optional
        Default: $false

        Will allow you to use Visual Studio command prompt tools from powershell
    .PARAMETER SSASAssemblies
        Optional
        Default: $false

        Attempts to install the SSAS assemblies. 
    .PARAMETER moduleDirs
        Optional
        Default: $null

        A list of paths that will be added to $env:PSModulePath
    .PARAMETER otherStuffToAdd
        Optional
        Default: $null

        Want to add some other arbitrary text to your profile? Do so here.
    .EXAMPLE
        This is what I use to setup my PROFILE at work
        & '.\Brandons System Setup.ps1' -alluserProfile -scriptPaths C:\source\github\friendly-chainsaw -installISEScriptSignAddOn -quickDirectories @{myGit = 'C:\source\TFS\Caboodle\Misc Developer Files\Brandon McClure'; caboodle = 'C:\source\TFS\Caboodle' } -moduleDirs @('C:\source\github\friendly-chainsaw\Modules\';'C:\source\TFS\Caboodle\Powershell Scripts\Modules\') -VSCommandPrompt -SSASAssemblies -ModulesToImportInProfile @("Posh-git")
    #>
[CmdletBinding(SupportsShouldProcess = $true)] #This line lets us use the -Verbose switch, and then some. See Get-Help CmdletBinding
param([switch]$updateHelp = $false
  ,[switch]$alluserProfile = $true
  ,[string]$scriptPaths = $null
  ,[switch]$installGitFetchJob = $false
  ,[switch]$installISEScriptSignAddOn = $false
  ,[string[]]$ModulesToImportInProfile = @("FC_Log","FC_Git","FC_Core")
  ,$quickDirectories = $null
  ,[string[]]$moduleDirs = $null
  ,[string]$notepadPlusPlusPath = "C:\Program Files (x86)\Notepad++\notepad++.exe"
  ,[string]$otherStuffToAdd = $null
  ,[switch]$VSCommandPrompt = $false
  ,[switch]$SSASAssemblies = $false
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
  Write-Error "Please rerun this script as an admin" -ErrorAction Stop
}

if (![System.Diagnostics.EventLog]::SourceExists("FC Powershell Scripts")) {
  Write-Host "Creating Windows Event log source named: FC Powershell Scripts"
  New-EventLog -LogName Application -Source "FC Powershell Scripts"
}
else {
  Write-Host "Windows Event log already exists for source: FC Powershell Scripts"
}


if ($alluserProfile -eq $true) {
  $ProfileDir32 = "$env:windir\system32\WindowsPowerShell\v1.0\profile.ps1"
  $profileDir64 = "$env:windir\SysWOW64\WindowsPowerShell\v1.0\profile.ps1"
  New-Item –Path $ProfileDir32 –Type File –Force
  New-Item –Path $ProfileDir64 –Type File –Force
}
else {
  $ProfileDir32 = "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
  $profileDir64 = $null
  New-Item –Path $ProfileDir –Type File –Force
}

$NOW = Get-Date
"<#
    This is a automaticly generated file created by the script 'Brandons System Setup.ps1' Any changes to this file will be overwritten the next time this script is run. 
    See the TFS git repository 'PowerShell Scripts' in the Epic project for more information

    Generated: $NOW
 #>
 " | Add-Content -Path $ProfileDir32,$profileDir64

if ($updateHelp -eq $true) {
  #TODO: Run this in the background as a job
  "Update-Help" | Add-Content -Path $ProfileDir32,$profileDir64
}

if (!([string]::IsNullOrEmpty($moduleDirs))) {
  foreach ($dir in $moduleDirs) {
    'if (!($env:PSModulePath -Like "*;' + $dir + '\*")){
                    $env:PSModulePath = $env:PSModulePath + ";' + $dir + ';"
        }' | Add-Content -Path $ProfileDir32,$profileDir64
  }
}

$validModules = (Get-Module).Name
if (!([string]::IsNullOrEmpty($ModulesToImportInProfile))) {
  foreach ($module in $ModulesToImportInProfile) {
    if ($module -in $validModules) {
      "Import-Module $module -DisableNameChecking" | Add-Content -Path $ProfileDir32,$profileDir64
    }
    else {
      Write-Warning "$module is not a valid modulename"
    }
  }
}

if (!([string]::IsNullOrEmpty($scriptPaths))) {
  "
    Set-Location ""$scriptPaths""
    " | Add-Content -Path $ProfileDir32,$profileDir64
}
#Create a scheduled job (see about_scheduledjobs) that will run my script that fetches remote branch information for all my git repos at 2am (+ or - 1 hour) every day
if ($installGitFetchJob) {
  if (!(Get-ScheduledJob -Name "Fetch branches for Git repos")) {
    Register-ScheduledJob -Name "Fetch branches for Git Repos" -FilePath "$($scriptPaths)\Git Scripts\Git-FetchBranches.ps1" -Trigger (New-JobTrigger -At 2:00 -Daily -RandomDelay 01:00:00)
  }
}


if (!([string]::IsNullOrEmpty($quickDirectories))) {
  $output = '$myDirs = @{
    '

  foreach ($key in $quickDirectories.Keys) {
    $output += "$key = '$($quickDirectories.Item($key))'
        "
  }
  $output += "}
"
  $output | Add-Content $ProfileDir32,$profileDir64
}

if (Test-Path $notepadPlusPlusPath) {
  Write-Verbose "Creating an alias for notepad ++"
  "New-Alias npp '$notepadPlusPlusPath'" | Add-Content $ProfileDir32,$profileDir64
}

if ($installISEScriptSignAddOn) {
  #One of the functions in BrandonLib is a script I got from the internet that will sign your currently loaded script in the ISE with your code signing certificate. Very handy to have in your ISE add-ons menu
  '
    #Check to see if the shell is the ISE or not. If it is the ISE, check to see if there is a action for Set-ScriptSignature. This will create 2 items in the menu. 
    #TODO: Check for nullness of the $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action
    if ([string]::IsNullOrEmpty($psISE)){
        break
    } 
    if ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action -eq $null ){
        $psISE.CurrentPowerShellTab.AddOnsMenu.submenus.add("Sign Script", {Set-ScriptSignature},$null) | Out-Null
        $psISE.CurrentPowerShellTab.AddOnsMenu.submenus.add("Beautify Script", {RunISE-DTWBeautifyScript},$null) | Out-Null
    }
    elseif ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action.Contains("Set-ScriptSignature")) {
        $psISE.CurrentPowerShellTab.AddOnsMenu.submenus.add("Sign Script", {Set-ScriptSignature},$null) | Out-Null
    }
    elseif ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action.Contains("RunISE-DTWBeautifyScript")) {
        $psISE.CurrentPowerShellTab.AddOnsMenu.submenus.add("Beautify Script", {RunISE-DTWBeautifyScript},$null) | Out-Null
    }
    ' | Add-Content -Path $ProfileDir32,$profileDir64
}

if ($VSCommandPrompt) {
  '
    pushd "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\Tools"
cmd /c "VsDevCmd.bat&set" |
foreach {
  if ($_ -match "=") {
    $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
  }
}
popd
    ' | Add-Content -Path $ProfileDir32,$profileDir64
}

if ($SSASAssemblies) {
  '
    try{
    Write-Log "loading Microsoft.AnalysisServices assemblies that we need" Debug
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Core") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices.Tabular") | Out-Null
}
catch{
    Write-Log "Could not load the needed assemblies... TODO: Figure out and document how to install the needed assemblies. (I would start with the SQL feature pack)" Error
}
' | Add-Content -Path $ProfileDir32,$profileDir64
}

if (![string]::IsNullOrEmpty($otherStuffToAdd)) {
  $otherStuffToAdd | Add-Content -Path $ProfileDir32,$profileDir64
}
