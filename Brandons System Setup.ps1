<#
    .Synopsis
      This script is designed to setup the powershell profile based on the various system configurations that we use. Specifically I use this on my laptop and development VM to ensure consistent settings. 
    .DESCRIPTION
        Sets the $env:PSModulePath variable to to T drive unc path for our deployed modules. Loads the BrandonLib module proactivly (I use it all the time!) and adds a item in the Add-On menu of the ISE which lets you easily sign your scripts. 
    .PARAMETER scriptPaths
        The location of your Modules directory. This is useful for me as I can switch between the published modules on the T drive, and my local copy for doing development. This needs to be the directory directly above your module directory IE C:\PowerShell not C:\PowerShell\Modules
    .alluserProfile
        Defaults to true
        Sets up the all user profile. If set to false it will setup the user profile. 
    .PARAMETER updateHelp
        Adds the command "Update-Help" to the profile. Not recomended as it currently runs in the foreground. 
    .PARAMETER installPoshGit
        Installs the PoshGit module using PowerShellGet. There are .net dependencies with this, but is highly recomended if you use command line git often. 
        See their github page for more info: https://github.com/dahlbyk/posh-git
    .PARAMETER installGitFetchJob
        Experimental. Installs a powershell scheduled job that performs a git fetch --all for all repos under a given subdirectory. Hardcoded to my folder structure ATM. 
    .PARAMETER installISEScriptSignAddOn
        Adds a add-on to the powershell ISE that allows you to sign your script with one click. Highly recomended.
    
    #>
[CmdletBinding(SupportsShouldProcess=$true)]  #This line lets us use the -Verbose switch, and then some. See Get-Help CmdletBinding
param([switch] $updateHelp = $false
,[switch] $alluserProfile = $true
,[string] $scriptPaths = "\\dhdcdept1\dept\Epic Program\Reporting Team\Builds\Powershell Scripts"
,[switch] $installPoshGit = $false
,[switch] $installGitFetchJob = $false
,[Switch] $installISEScriptSignAddOn = $false)

if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    Write-Error "Please rerun this script as an admin" -ErrorAction Stop
}

if (![System.Diagnostics.EventLog]::SourceExists("Cogito - Powershell Scripts")){
    New-EventLog -LogName Application -Source "Cogito - Powershell Scripts"
}


if ($alluserProfile -eq $true){
 $ProfileDir32 = "$env:windir\system32\WindowsPowerShell\v1.0\profile.ps1"
 $profileDir64 = "$env:windir\SysWOW64\WindowsPowerShell\v1.0\profile.ps1"
 New-Item –Path $ProfileDir32 –Type File –Force
  New-Item –Path $ProfileDir64 –Type File –Force
 }
 else{
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
 " | Add-Content -Path $ProfileDir32, $profileDir64

 if ($updateHelp -eq $true){
 #TODO: Run this in the background as a job
    "Update-Help" | Add-Content -Path $ProfileDir32, $profileDir64
}


#Setup the Module path to our custom modules, and load Logger so we can log stuff
'
    if (!($env:PSModulePath -Like "*;'+$($scriptPaths)+'\Modules\*")){
        $env:PSModulePath = $env:PSModulePath + ";'+$($scriptPaths)+'\Modules\"
}
if (!($env:PSModulePath -Like "*;'+$($env:USERPROFILE)+'\Documents\WindowsPowerShell\Modules\*")){
        $env:PSModulePath = $env:PSModulePath + ";'+$($env:USERPROFILE)+'\Documents\WindowsPowerShell\Modules\"

}
Import-Module Logger' | Add-Content -Path $ProfileDir32, $profileDir64

if ($installPoshGit){
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
'
Import-Module Posh-git' | Add-Content -Path $ProfileDir32, $profileDir64
}

"Set-Location ""$scriptPaths""" | Add-Content -Path $ProfileDir32, $profileDir64

#Create a scheduled job (see about_scheduledjobs) that will run my script that fetches remote branch information for all my git repos at 2am (+ or - 1 hour) every day
IF ($installGitFetchJob){
    if (!(Get-ScheduledJob -Name "Fetch branches for Git repos")){
        Register-ScheduledJob -Name "Fetch branches for Git Repos" -FilePath "$($scriptPaths)\Git Scripts\Git-FetchBranches.ps1" -Trigger (New-JobTrigger -At 2:00 -Daily -RandomDelay 01:00:00)
    }
}

if ($installISEScriptSignAddOn){
    #One of the functions in BrandonLib is a script I got from the internet that will sign your currently loaded script in the ISE with your code signing certificate. Very handy to have in your ISE add-ons menu
    '
    #Check to see if the shell is the ISE or not. If it is the ISE, check to see if there is a action for Set-ScriptSignature. This will create 2 items in the menu. 
    #TODO: Check for nullness of the $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action
    if ([string]::IsNullOrEmpty($psISE)){
        break
    } 
    if ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action -eq $null ){
        $psISE.CurrentPowerShellTab.AddOnsMenu.submenus.add("Sign Script", {Set-ScriptSignature},$null) | Out-Null
    }
    elseif ($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Action.Contains("Set-ScriptSignature")) {
        $psISE.CurrentPowerShellTab.AddOnsMenu.submenus.add("Sign Script", {Set-ScriptSignature},$null) | Out-Null
    }
    '| Add-Content -Path $ProfileDir32, $profileDir64
}
 