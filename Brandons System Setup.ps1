<#
    .Synopsis
      This script was initially written to setup the powershell profile on my systems at work. At some point this will be split into a more general use system setup script and and Install-FC script. Right now it makes some assumptions on how your Powershell environment works.  
    .DESCRIPTION
        This script works by modifiyng the $profile for all users, or the user running the script. I have always used this for all users, all hosts. So I am unsure how well this approach would work with indiviudal profiles. 

        
    .PARAMETER scriptPaths
        Optional
        Default: $null

        If specified, this is the location your shell will default to, and $env:PSModulePath will be modified as part of your profile code to look for module in a subdirectory called "modules"

        My general philosophy
        Instead of installing the modules to each client, it is more useful in my environment to publish the modules to a network share that everyone can read, only our CI account can write to.
        This setup script modifies $env:PSModulePath in the profile (so for each PS Session. I found this to be more stable than attmepting to edit the PSModule path globally, primarally because it was difficult to switch between development modules and production modules on my workstation, but also due to the risk of breaking the variable. 

    .alluserProfile
        Optional
        Defaults: true

        Sets up the all user profile. If set to false it will setup the user profile. (The user profile is not tested)
    .PARAMETER updateHelp
        Optional
        Default: false

        Adds the command "Update-Help" to the profile. Not recomended as it currently runs in the foreground. 
    .PARAMETER installPoshGit
        Optional
        Default: false

        Installs the PoshGit module using PowerShellGet. There are .net dependencies with this, but is highly recomended if you use command line git often. 
        See their github page for more info: https://github.com/dahlbyk/posh-git
    .PARAMETER installGitFetchJob
        Optional
        Default: false

        Experimental. Installs a powershell scheduled job that performs a git fetch --all for all repos under a given subdirectory. Hardcoded to my folder structure ATM. 
    .PARAMETER installISEScriptSignAddOn
        Optional
        Default: false

        Adds a add-on to the powershell ISE that allows you to sign your script with one click. Highly recomended.
	.PARAMETER installCommunityExtensions
        Optional
        Default: false

        Installs the Powershell Cimmunity Extensions. Recomended.
        
        https://github.com/Pscx/Pscx	
    .PARAMETER ModulesToImportInProfile
        Optional
        Default: @("FC_Log","FC_Git","FC_Core")	
        
        An array of modules to import as part of the profile code. These will be imported for every shell							 
    
    #>
[CmdletBinding(SupportsShouldProcess=$true)]  #This line lets us use the -Verbose switch, and then some. See Get-Help CmdletBinding
param([switch] $updateHelp = $false
,[switch] $alluserProfile = $true
,[string] $scriptPaths = $null
,[switch] $installPoshGit = $false
,[switch] $installGitFetchJob = $false
,[Switch] $installISEScriptSignAddOn = $false
,[Switch] $installCommunityExtensions = $false
,[string[]] $ModulesToImportInProfile = @("FC_Log","FC_Git","FC_Core"))

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
if (!($env:PSModulePath -Like "*;'+$($scriptPaths)+'\Modules\*")){
        $env:PSModulePath = $env:PSModulePath + ";'+$($scriptPaths)+'\Modules\"
}
if (!($env:PSModulePath -Like "*;'+$($env:USERPROFILE)+'\Documents\WindowsPowerShell\Modules\*")){
        $env:PSModulePath = $env:PSModulePath + ";'+$($env:USERPROFILE)+'\Documents\WindowsPowerShell\Modules\"

}

'
    if (!($env:PSModulePath -Like "*;'+$($scriptPaths)+'\Modules\*")){
        $env:PSModulePath = $env:PSModulePath + ";'+$($scriptPaths)+'\Modules\"
}
if (!($env:PSModulePath -Like "*;'+$($env:USERPROFILE)+'\Documents\WindowsPowerShell\Modules\*")){
        $env:PSModulePath = $env:PSModulePath + ";'+$($env:USERPROFILE)+'\Documents\WindowsPowerShell\Modules\"

}
' | Add-Content -Path $ProfileDir32, $profileDir64

$validModules = @("FC_Log","FC_Git","FC_Core")
if (!([string]::IsNullOrEmpty($ModulesToImportInProfile))){
    foreach ($module in $ModulesToImportInProfile){
        if ($module -in $validModules){
            "Import-Module $module" | Add-Content  -Path $ProfileDir32, $profileDir64
        }
        else{
            Write-Warning "$module is not a valid modulename"
        }
    }
}

if ($installPoshGit){
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
'
Import-Module Posh-git
' | Add-Content -Path $ProfileDir32, $profileDir64
}

if ($installCommunityExtensions){
    Install-Module Pscx
}								 
"
Set-Location ""$scriptPaths""
" | Add-Content -Path $ProfileDir32, $profileDir64

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
 