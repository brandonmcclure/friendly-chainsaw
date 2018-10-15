function Remove-SpeechCommands {
    #.Synopsis
    #  Remove one or more command from the speech-recognition macros, and update the recognition
    #.Parameter CommandText
    #  The string key for the command to remove
    Param([string[]]$CommandText)
    foreach ($command in $CommandText) {
        $script:SpeechModuleMacros.Remove($Command)
    }
    Update-SpeechCommands
}