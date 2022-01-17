<#
    .Synopsis
      Runs a pomodoro timer https://en.wikipedia.org/wiki/Pomodoro_Technique
    .DESCRIPTION
      When you run this from powershell.exe the script will start a timer for 25 minutes, then prompt you to press enter to move onto a 5 minute break timer. You can rerun this script to start another timer cycle untill you complete your circuit/take a longer break. 
    #>
[CmdletBinding(SupportsShouldProcess = $true)] 
param([Parameter(position = 0)][ValidateSet("Debug", "Info", "Warning", "Error", "Disable")][string] $logLevel = "Info"
	, $breakDurationMin = 5
	, $pomodoromDurationMin = 25
)
	
Import-Module FC_Log
	
if ([string]::IsNullOrEmpty($logLevel)) { $logLevel = "Info" }
Set-LogLevel $logLevel
	
Set-logTargets -Speech 1

function Invoke-AlertMessage {
	param($alertMessage)

	if ([string]::IsNullOrEmpty($alertMessage)) {
		Write-Log "You must specify a alertMessage" Error -ErrorAction Stop
	}
	$alarmStageActive = $true
	while ($alarmStageActive) {
		Write-Log $alertMessage
		if ([console]::KeyAvailable) {
			
			$x = [System.Console]::ReadKey() 
	
			switch ( $x.key) {
				enter { $alarmStageActive = $false }
			}
		}
		Start-Sleep 1	
	}
}

Write-Log "Starting the pomodoro timer for $pomodoromDurationMin minutes"
Start-Sleep -Seconds (60 * $pomodoromDurationMin)
Invoke-AlertMessage -AlertMessage "The pomodoro timer is up, press enter to move to the break timer"

Write-Log "Starting $breakDurationMin minute break"
Start-Sleep -Seconds (60 * $breakDurationMin)

Invoke-AlertMessage -AlertMessage "The break timer is up, press enter to complete the cycle"
