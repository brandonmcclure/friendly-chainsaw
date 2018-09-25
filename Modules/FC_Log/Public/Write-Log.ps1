function Write-Log {
<#
    .Synopsis
       Writes a message to one of several streams/targetd. The default "info" messages use Write-Information and set the informationprefer
	.Description
        Write-Log is the central function for the FC_Log module. It is designed to wrap the several ways to log data into one easy to use function. Using Write-Log in your script, you can then decide at run time if you want your messages to display or not, and to what stream you want them written. A common use is to Set-logLevel to Error when the scripts are running in production, and then if an error occurs reruning the scripts with Debug level, and possible write to the Windows event log to help you in troubleshooting. 

        Messages can be written to the windows event log in addition with being returned via a powershell stream based on how the logger has been configured. 
        
        There is also limited formatting that will be applied. The formatiing is set in the Set-LogFormattingOptions function 
        
		NOTE: When you use -ErrorAction Stop on this function it will not write any errors in the calling scope
	.PARAMETER Message
        Default: $null
        Position: 0

		The $Message parameter is the string that will be written. 
	.PARAMETER EventLevel
        Position: 2
		Specifies the entry type of the event. Position=1 
		Valid values are "Debug","Verbose","Info","Warning","Error"

        The default level of Info is used if not specified. Write-Log checks against the script scoped logLevel, if the EventLevel is lower than the script scoped $logLevel then the message will be written to the appropriate stream (Write-Debug,Write-Verbose,Write-Information,Write-Warning, or Write-Error)
	.PARAMETER eventID
        Position:  3
		Only used when you Set-logTargetWinEvent on. The Event ID for the windows event log. Can be any number between 0 and 65535, defaults to 10. 
     .EXAMPLE
        Writes a message as a Information event level. Good for general logging to the screen. The Information preference variable is set to 'Continue' for the scope of the call so that the message will be deployed regardless of the caller's preference.

       Write-Log "Basic information message"
 
	.EXAMPLE
        Writing a error message to the Windows Event Log a message as a Error event level, with the max eventID value of 65535. This will call Write-Error to raise an error on the PowerShell host, and write the log to the Windows Event log with the event ID: 65535

        Set-logTargetWinEvent $true

       Write-Log "Testing out a error message" Error -eventID 65535
    .INPUTS
        Accepts a string value for the message that will be written
    #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $True,Position = 0)] [string]$Message = "",
    [Parameter(Position = 1)][ValidateSet("Debug","Verbose","Info","Warning","Error","Disable")] [string]$EventLevel = "Info",
    [Parameter(Position = 2)] [int]$eventID = 10,
    [Parameter(Position = 3)] [int]$tabLevel = 0

  )

  if ($script:LogLevel -eq 100) {
    return
  }
  $messageLevel = $script:logLevelOptions[$EventLevel]
  #Set the Verbose preference to the value in the calling script
  Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

  $tabs = ''
  if ($script:logFormattingOptions['AutoTabCallsFromFunctions'] -eq 1) {
    $callingFunction = (Get-PSCallStack | Select-Object FunctionName -Skip 1 -First 1).FunctionName | Where-Object { $_ -ne '<ScriptBlock>' }
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


  #Debug Messages
  if ($messageLevel -eq 0 -and $script:LogLevel -eq 0) {
    if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
      $FormatMessage = "$tabs$timeStamp[$callingFunction][DEBUG] $Message"
    }
    else {
      $FormatMessage = "$tabs$timeStamp[DEBUG] $Message"
    }

    if ($DebugPreference -eq "Inquire" -or $DebugPreference -eq "Continue") {
      Write-Debug "$Message"
    }
    else {
      $VerbosePreference = 'Continue'
      Write-Verbose "$FormatMessage"
    }
    if ($script:logTargets['WindowsEventLog'] -eq 1) {
      Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
    }
    if ($script:logTargets['Speech'] -eq 1){
        Add-Type -AssemblyName System.speech
        $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $speak.Speak($Message)
    }
  }
  #Verbose Messages
  elseif ($messageLevel -eq 5 -and $script:LogLevel -le 5) {
    if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
      $FormatMessage = "$tabs$timeStamp[$callingFunction] $Message"
    }
    else {
      $FormatMessage = "$tabs$timeStamp $Message"
    }
    $VerbosePreference = 'Continue'
    Write-Verbose "$FormatMessage"
    if ($script:logTargets['WindowsEventLog'] -eq 1) {
      Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
    }
    if ($script:logTargets['Speech'] -eq 1){
        Add-Type -AssemblyName System.speech
        $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $speak.Speak($Message)
    }
  }
  #Info Messages
  elseif ($messageLevel -eq 10 -and $script:LogLevel -le 10) {
    if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
      $FormatMessage = "$tabs$timeStamp[$callingFunction] $Message"
    }
    else {
      $FormatMessage = "$tabs$timeStamp$Message"
    }
    $InformationPreference = 'Continue'
    Write-Information $FormatMessage
    if ($script:logTargets['WindowsEventLog'] -eq 1) {
      Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Information" -EventId $eventID -Message "$FormatMessage"
    }
    if ($script:logTargets['Speech'] -eq 1){
        Add-Type -AssemblyName System.speech
        $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $speak.Speak($Message)
    }

  }
  #Warning Messages
  elseif ($messageLevel -eq 20 -and $script:LogLevel -le 20) {
    if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
      $FormatMessage = "$tabs$timeStamp[$callingFunction][WARNING] $Message"
    }
    else {
      $FormatMessage = "$tabs$timeStamp[WARNING] $Message"
    }
    Write-Warning "$FormatMessage"
    if ($script:logTargets['WindowsEventLog'] -eq 1) {
      Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Warning" -EventId $eventID -Message "$FormatMessage"
    }

    if ($script:logTargets['Speech'] -eq 1){
        Add-Type -AssemblyName System.speech
        $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $speak.Speak($Message)
    }

  }
  #Error Messages
  elseif ($messageLevel -eq 30 -and $script:LogLevel -le 30) {
    if ($script:logFormattingOptions['PrefixCallingFunction'] -eq 1 -and !([string]::IsNullOrEmpty($callingFunction))) {
      $FormatMessage = "$tabs$timeStamp[$callingFunction] $Message"
    }
    else {
      $FormatMessage = "$tabs$timeStamp$Message"
    }
    Write-Error "$FormatMessage"
    if ($script:logTargets['WindowsEventLog'] -eq 1) {
      Write-EventLog -LogName Application -Source "$script:LogSource" -EntryType "Error" -EventId $eventID -Message "$FormatMessage"
    }
    if ($script:logTargets['Speech'] -eq 1){
        Add-Type -AssemblyName System.speech
        $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $speak.Speak($Message)
    }


  }
} Export-ModuleMember -Function Write-Log
