﻿function Write-Log {
<#
    .Synopsis
       Writes a message to one of several streams/targetd. The default "info" messages use Write-Information and set the informationprefer
	.Description
        Write-Log is the central function for the FC_Log module. It is designed to wrap the several ways to log data into one easy to use function. Using Write-Log in your script, you can then decide at run time if you want your messages to display or not, and to what stream you want them written. A common use is to Set-logLevel to Error when the scripts are running in production, and then if an error occurs reruning the scripts with Debug level, and possible write to the Windows event log to help you in troubleshooting. 

        Messages can be written to the windows event log in addition with being returned via a powershell stream based on how the logger has been configured. 
        
        There is also limited formatting that will be applied. The formating is set in the Set-LogFormattingOptions function 
	.PARAMETER Messages
        Default: $null
        Position: 0

		The $Messages parameter is an array of strings that will be logged. This will accept pipeline input.   
	.PARAMETER EventLevel
        Position: 2
		Specifies the entry type of the event. Position=1 
		Valid values are "Debug","Verbose","Info","Warning","Error"

        The default level of Info is used if not specified. Write-Log checks against the script scoped logLevel, if the EventLevel is lower than the script scoped $logLevel then the message will be written to the appropriate stream (Write-Debug,Write-Verbose,Write-Information,Write-Warning, or Write-Error) depending on the caller's preference and the messages EventLevel.
	.PARAMETER eventID
        Position:  3
		Only used when you Set-logTargetWinEvent on. The Event ID for the windows event log. Can be any number between 0 and 65535, defaults to 10. 
     .EXAMPLE
        Writes a message as a Information event level. Good for general logging to the screen. The Information preference variable is set to 'Continue' for the scope of the call so that the message will be deployed regardless of the caller's preference.

       Write-Log "Basic information message"
    .EXAMPLE
        Uses the pipeline to log all the running process names

       Get-Process | select -ExpandProperty name | Write-Log
 
	.EXAMPLE
        Writing a error message to the Windows Event Log a message as a Error event level, with the max eventID value of 65535. This will call Write-Error to raise an error on the PowerShell host, and write the log to the Windows Event log with the event ID: 65535

        Set-logTargetWinEvent $true

       Write-Log "Testing out a error message" Error -eventID 65535
    .INPUTS
        Accepts a array of string values for the message that will be written
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $True,Position = 0)] [string[]]$Messages = "",
    [Parameter(Position = 1)][ValidateSet("Debug","Verbose","Info","Warning","Error","Disable")] [string]$EventLevel = "Info",
    [Parameter(Position = 2)] [int]$eventID = 10,
    [Parameter(Position = 3)] [int]$tabLevel = 0

  )
  begin {
    if ($script:LogLevel -eq 100) {
      return
    }
    $msgLevel = $script:logLevelOptions[$EventLevel]
    #Set the Verbose preference to the value in the calling script
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

	$isWindowsEventLogTarget = $script:logTargets['WindowsEventLog']
	if( $PSVersionTable.PSEdition -eq 'core' -and $isWindowsEventLogTarget -eq 1 ){
		Write-Error "I cannot log to the Windows Event Log on pwsh core without some workarounds. See https://github.com/brandonmcclure/friendly-chainsaw/issues/61"
		$isWindowsEventLogTarget = 0
	}

    $tabs = ''
    if ($script:logFormattingOptions['PrefixScriptName'] -eq 1) {
      $scriptName = ""
      if([string]::IsnullOrEmpty($scriptName)){
        $scriptName = Get-CallingScript
    }
    if([string]::IsnullOrEmpty($scriptName)){
        Write-Error "Cannot set the scriptName" -ErrorAction Stop
    }
  }
  $callingFunction = ""
    if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1) {
      $callingFunction = Get-CallingFunction

    }
    if ($script:logFormattingOptions['AutoTabCallsFromFunctions'] -eq 1) {
      $callingFunction = (Get-PSCallStack | Select-Object -Skip 1 -First 1 | Where-Object { $_.Command -ne '<ScriptBlock>' }).FunctionName 
      if (!([string]::IsNullOrEmpty($callingFunction))) {
        $tabLevel++
      }
    }
    for ($i = 1; $i -le $tabLevel | Where-Object { $_ -ne 0 }; $i++) {
      $tabs = $tabs + '     '
    }

    $timeStamp = ''
    if ($script:logFormattingOptions['PrefixTimestamp'] -eq 1) {
      $timeStamp = "$(Get-Date) - "
    }
  }
  process {
    foreach ($msg in $Messages) {
      #Debug Messages
      if ($msgLevel -eq 0 -and $script:LogLevel -eq 0) {
        if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
            $FormatMessage = "$tabs$timeStamp[$callingFunction][DEBUG] $msg"
        }
        elseif ($script:logFormattingOptions['PrefixScriptName'] -eq 1 -and !([string]::IsNullOrEmpty($scriptName))) {
          $FormatMessage = "$tabs$timeStamp[$scriptName][DEBUG] $msg"
        }
        else {
          $FormatMessage = "$tabs$timeStamp[DEBUG] $msg"
        }

        if($script:logTargets['Console'] -eq 1){
            if ($DebugPreference -eq "Inquire" -or $DebugPreference -eq "Continue") {
              Write-Debug "$msg"
            }
            else {
              $VerbosePreference = 'Continue'
              Write-Verbose "$FormatMessage"
            }
        }
        if ($isWindowsEventLogTarget -eq 1) {
          Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
        }
        if ($script:logTargets['Speech'] -eq 1) {
          Add-Type -AssemblyName System.speech
          $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
          $speak.Speak($msg)
        }
      }
      #Verbose Messages
      elseif ($msgLevel -eq 5 -and $script:LogLevel -le 5) {
        if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
          $FormatMessage = "$tabs$timeStamp[$callingFunction] $msg"
        }
        elseif ($script:logFormattingOptions['PrefixScriptName'] -eq 1 -and !([string]::IsNullOrEmpty($scriptName))) {
          $FormatMessage = "$tabs$timeStamp[$scriptName] $msg"
        }
        else {
          $FormatMessage = "$tabs$timeStamp $msg"
        }
        if($script:logTargets['Console'] -eq 1){
            $VerbosePreference = 'Continue'
            Write-Verbose "$FormatMessage"
        }
        if ($isWindowsEventLogTarget -eq 1) {
          Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
        }
        if ($script:logTargets['Speech'] -eq 1) {
          Add-Type -AssemblyName System.speech
          $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
          $speak.Speak($msg)
        }
      }
      #Info Messages
      elseif ($msgLevel -eq 10 -and $script:LogLevel -le 10) {
        if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
          $FormatMessage = "$tabs$timeStamp[$callingFunction] $msg"
        }
        elseif ($script:logFormattingOptions['PrefixScriptName'] -eq 1 -and !([string]::IsNullOrEmpty($scriptName))) {
          $FormatMessage = "$tabs$timeStamp[$scriptName] $msg"
        }
        else {
          $FormatMessage = "$tabs$timeStamp$msg"
        }
        if($script:logTargets['Console'] -eq 1){
            $InformationPreference = 'Continue'
            Write-Information $FormatMessage
        }
        if ($isWindowsEventLogTarget -eq 1) {
          Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
        }
        if ($script:logTargets['Speech'] -eq 1) {
          Add-Type -AssemblyName System.speech
          $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
          $speak.Speak($msg)
        }

      }
      #Warning Messages
      elseif ($msgLevel -eq 20 -and $script:LogLevel -le 20) {
        if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
          $FormatMessage = "$tabs$timeStamp[$callingFunction][WARNING] $msg"
        }
        elseif ($script:logFormattingOptions['PrefixScriptName'] -eq 1 -and !([string]::IsNullOrEmpty($scriptName))) {
          $FormatMessage = "$tabs$timeStamp[$scriptName][WARNING] $msg"
        }
        else {
          $FormatMessage = "$tabs$timeStamp[WARNING] $msg"
        }
        if($script:logTargets['Console'] -eq 1){
            Write-Warning "$FormatMessage"
        }
        if ($isWindowsEventLogTarget -eq 1) {
          Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Warning" -EventId $eventID -Message "$FormatMessage"
        }

        if ($script:logTargets['Speech'] -eq 1) {
          Add-Type -AssemblyName System.speech
          $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
          $speak.Speak($msg)
        }

      }
      #Error Messages
      elseif ($msgLevel -eq 30 -and $script:LogLevel -le 30) {
        if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
          $FormatMessage = "$tabs$timeStamp[$callingFunction] $msg"
        }
        elseif ($script:logFormattingOptions['PrefixScriptName'] -eq 1 -and !([string]::IsNullOrEmpty($scriptName))) {
          $FormatMessage = "$tabs$timeStamp[$scriptName] $msg"
        }
        else {
          $FormatMessage = "$tabs$timeStamp$msg"
        }
        if($script:logTargets['Console'] -eq 1){
            Write-Error "$FormatMessage"
        }
        if ($isWindowsEventLogTarget -eq 1) {
          Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Error" -EventId $eventID -Message "$FormatMessage"
        }
        if ($script:logTargets['Speech'] -eq 1) {
          Add-Type -AssemblyName System.speech
          $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
          $speak.Speak($msg)
        }


      }

      if ($script:logTargets['File'] -eq 1) {
        foreach($file in $script:logTargetFileNames){
			$fileParentDir = Split-Path $file -Parent
                if (-not (Test-Path $fileParentDir)){
					try{
						New-Item -Path $fileParentDir -ItemType Directory -Force
					}
					catch{
						throw "Could not set log target to: $fileParentDir. Path does not exist"
					}
				}
        $i = 0;
        $repeat = $true
        while($repeat){
          $i++;
          if($i -gt 9){
            $repeat = $false
          }
        try{
            $FormatMessage | Add-Content $file -ErrorAction Stop
            $repeat = $false
        }
        catch{

        }

        
      }
        }
      }
    }
  }
} Export-ModuleMember -Function Write-Log
