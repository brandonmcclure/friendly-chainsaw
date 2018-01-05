<#
    .Synopsis
      Will install Pandoc on a Windows PC. It does this by downloading the latest .msi release
    .DESCRIPTION
      Tested on Windows 7 Enterprise. 

    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info"
,[Parameter(position=1)][string] $specifiedTag = $null
,[switch] $winEventLog
,[switch] $cleanupLocalFiles)

Import-Module FC_Log, FC_Git -Force

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog
Set-LogFormattingOptions -PrefixCallingFunction 1 -AutoTabCallsFromFunctions 1

Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug

try{
    choco install pandoc -y
    choco install miktex -y
}
catch{
    $ex = $_.Exception
    $errorLine = $_.InvocationInfo.ScriptLineNumber
    $errorMessage = $ex.Message 
    Write-Log "Error at line $errorLine. Error message: $errorMessage" Warning
}


Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
