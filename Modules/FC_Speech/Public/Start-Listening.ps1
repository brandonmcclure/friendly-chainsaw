function Start-Listening {
    #.Synopsis
    #  Sets the SpeechRecognizer to Enabled
    $global:SpeechModuleListener.Enabled = $true
    Say "Speech Macros are $($Global:SpeechModuleListener.State)"
    Write-Log "Speech Macros are $($Global:SpeechModuleListener.State)"
}Export-ModuleMember -Function Start-Listening