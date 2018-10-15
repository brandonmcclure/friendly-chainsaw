function Out-Speech {
    #.Synopsis
    #  Speaks the input object
    #.Description
    #  Uses the default SpeechSynthesizer settings to speak the string representation of the InputObject
    #.Parameter InputObject
    #  The object to speak 
    #  NOTE: this should almost always be a pre-formatted string,
    #        most objects don't render to very speakable text.
    Param([Parameter(ValueFromPipeline=$true)][Alias("IO")]$InputObject)
    $null = $global:SpeechModuleSpeaker.SpeakAsync(($InputObject | Out-String))
}Export-ModuleMember -Function Out-Speech