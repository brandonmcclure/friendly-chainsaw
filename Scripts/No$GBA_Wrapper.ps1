[CmdletBinding(SupportsShouldProcess=$true)]  #This line lets us use the -Verbose switch, and then some. See Get-Help CmdletBinding
param(
	[ValidateNotNullOrEmpty()][string] $logLevel = "Debug",
	[string] $emulatorPath = "C:\RomsAndSuch\GBA\Emulators\NO`$GBA.EXE",
    [string] $JoystickerProDir = "C:\RomsAndSuch\JoystickerPro"
,[int] $loopSleepTime = 5 )

Import-Module FC_Core,FC_Log,FC_Git -Force

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog
Set-LogFormattingOptions -PrefixCallingFunction 1 -AutoTabCallsFromFunctions 1

Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug

Write-Log "Starting JoystickerPro"
$JoystickerProPath = "$JoystickerProDir\JoystickerPro.exe"
if (Test-Path $JoystickerProPath){
    if ((Get-Process | Where {$_.Name -eq 'JoystickerPro'}).Count -eq 0){
        $joystickerProc = Start-MyProcess -EXEPath $JoystickerProPath -async -workingDir $JoystickerProDir
    }
    else{
        Write-Log "JoystickerPro is already running"
    }
}
else{
    Write-Log "Could not start JoystickerPro; $JoystickerProPath is not a valid path"
}

$emulatorDir = Split-PAth $emulatorPath -Parent
Write-Log "Checking if the configuration is correct"
$file = Get-Content "$emulatorDir\NO`$GBA.INI" 
$filter = $file | foreach-object { $_ -replace '^Number of Emulated Gameboys == [a-z -]+','Number of Emulated Gameboys == -Single Machine'  }
$filter = $filter | foreach-object { $_ -replace '^Load ROM-Images to == [a-z 1-9-]+','Load ROM-Images to == -All machines'   }
$filter | Set-Content -Path "$emulatorDir\NO`$GBA.INI" 
Write-Log "Configuration check complete"
Write-LOg "Invoking AutoGit on the save directory"
Invoke-AutoGit -path "$emulatorDir\BATTERY" -pushOnCompletion | Out-Null
Try{
    Write-Log "Starting the emulator, the script will hang while the emulator is running"
    $processResult = Start-MyProcess -EXEPath $emulatorPath
    Write-Log "Emulator process is completing, stoping the AutoGit job"
}
Finally{
    Stop-AutoGit
    Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
}

