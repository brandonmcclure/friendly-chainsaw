function Remove-SpeechXP {
    #.Synopis
    #  Dispose of the SpeechModuleListener and SpeechModuleSpeaker
    $global:SpeechModuleListener.Dispose(); $global:SpeechModuleListener = $null
    $global:SpeechModuleSpeaker.Dispose();  $global:SpeechModuleSpeaker = $null
}