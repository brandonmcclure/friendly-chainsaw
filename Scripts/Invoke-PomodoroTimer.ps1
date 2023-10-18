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

$Messages_pomTimerUp = @(
	"The pomodoro timer is up, press enter to move to the break timer",
	"The work timer is up, press enter to move to the break timer",
	"I am evolving, the time is done. Press enter please",
	"I have nothing better to do then to wait for you to press enter.",
	"waiting for you to press enter"
)
$Messages_breakTimerUp = @(
	"The break timer is up, press enter to complete the cycle",
	"The break timer is up, press enter",
	"I am evolving, the timer is done. Press enter finish",
	"I have nothing better to do then to wait for you to press enter.",
	"waiting for you to press enter"
)
Import-Module FC_Log
	
if ([string]::IsNullOrEmpty($logLevel)) { $logLevel = "Info" }
Set-LogLevel $logLevel
	
Set-logTargets -Speech 1

function Start-SleepWithProgress($seconds,$status = "Sleeping") {
    $doneDT = (Get-Date).AddSeconds($seconds)
    while($doneDT -gt (Get-Date)) {
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        Write-Progress -Activity $status -Status "$status..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        [System.Threading.Thread]::Sleep(500)
    }
    Write-Progress -Activity $status -Status "$status..." -SecondsRemaining 0 -Completed
}

function Invoke-AlertMessage {
	param([string[]]$alertMessage)

	$numOfAlertMessages = $alertMessage | Measure-Object | Select-Object -ExpandProperty Count
	if ($numOfAlertMessages -eq 0) {
		Write-Log "You must specify a alertMessage" Error -ErrorAction Stop
	}
	
	$alarmStageActive = $true
	while ($alarmStageActive) {
		$currentMessage = $alertMessage | Sort-Object {Get-Random -Minimum 1 -Maximum ($numOfAlertMessages+1)} | Select-Object -first 1
		Write-Log $currentMessage
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
Start-SleepWithProgress -Seconds (60 * $pomodoromDurationMin) -status "Pomodoroing"

Invoke-AlertMessage -AlertMessage $Messages_pomTimerUp

Write-Log "Starting $breakDurationMin minute break"
Start-SleepWithProgress -Seconds (60 * $breakDurationMin) -status "breaking"

Invoke-AlertMessage -AlertMessage $Messages_breakTimerUp
