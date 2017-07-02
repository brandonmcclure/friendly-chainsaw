#requires -version 4.0
#requires –runasadministrator
<#
    .Synopsis
      This script is designed to setup the powershell profile to setup the powershell module directory as needed, and to set some settings that I find are helpful. 
    .DESCRIPTION
        Sets the $env:PSModulePath variable to to T drive unc path for our deployed modules. Loads the BrandonLib module proactivly (I use it all the time!) and adds a item in the Add-On menu of the ISE which lets you easily sign your scripts. 
     .PARAMETER modulePath
        Path to the directory that holds the friendly-chainsaw modules. Can be UNC or local. Must end with a backslash. 
        
        C:\friendly-chainsaw\modules\

        \\MyPCName\friendly-chainsaw\modules\
    .PARAMETER LoggerWindowsEventLogSource
        The Windows event log source that will be used for the logger. Defaults to null

        If null, no change is made to 
          
    #>
[CmdletBinding(SupportsShouldProcess=$true)]  #This line lets us use the -Verbose switch, and then some. See Get-Help CmdletBinding
param([switch] $alluserProfile = $true
,[string] $scriptPaths = "C:\Source\TFS\PowerShell Scripts"
,[string] $modulePath = $null 
,[string] $LoggerWindowsEventLogSource = $null #"FC Powershell Scripts")

IF (!([string]::IsNullOrEmpty($LoggerWindowsEventLogSource))){
    if (![System.Diagnostics.EventLog]::SourceExists("$LoggerWindowsEventLogSource")){
        New-EventLog -LogName Application -Source "$LoggerWindowsEventLogSource"
    }
}


if ($alluserProfile -eq $true){
     $ProfileDir32 = "$env:windir\system32\WindowsPowerShell\v1.0\profile.ps1"
     $profileDir64 = "$env:windir\SysWOW64\WindowsPowerShell\v1.0\profile.ps1"
     $ProfileDir = "$ProfileDir32,$ProfileDir64"
     New-Item –Path $ProfileDir32 –Type File –Force
     New-Item –Path $ProfileDir64 –Type File –Force
 }
 else{
    $ProfileDir32 = "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
    $ProfileDir = "$ProfileDir32"
    New-Item –Path $ProfileDir32 –Type File –Force
 }

 "<#
    This is a automaticly generated file created by the friendly-chainsaw script 'System Setup.ps1' Any changes to this file will be overwritten the next time this script is run.
 #>
 " | Add-Content -Path $ProfileDir32,$ProfileDir64


#Setup the Module path to our custom modules. 
if (!([string]::IsNullOrEmpty($modulePath))){
    if (test-path $modulePath){
    '
     if (!($env:PSModulePath -Like "*'+$modulePath+';*")){
           $env:PSModulePath = $env:PSModulePath + ";'+$modulePath+'"
    } 
    Import-Module Logger' | Add-Content -Path $ProfileDir32, $profileDir64
    }
}

#Add the Set-ScriptSignature function to the add on menu in the ise
'
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

if (!([string]::IsNullOrEmpty($scriptPaths)) -and (Test-Path $scriptPaths)){
    "cd ""$scriptPaths""" | Add-Content -Path $ProfileDir32, $profileDir64
 }