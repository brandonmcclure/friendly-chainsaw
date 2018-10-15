function Suspend-Listening {
    #.Synopsis
    #  Sets the SpeechRecognizer to Disabled
    $global:SpeechModuleListener.Enabled = $false
    Say "Speech Macros are disabled"
    Write-Host "Speech Macros are disabled"
}