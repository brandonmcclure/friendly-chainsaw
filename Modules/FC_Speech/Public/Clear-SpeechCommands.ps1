function Clear-SpeechCommands {
    #.Synopsis
    #  Removes all commands from the speech-recognition macros, and update the recognition
    #.Parameter CommandText
    #  The string key for the command to remove
    $script:SpeechModuleMacros = @{}
    ## Default value: A way to turn it off
    $script:SpeechModuleMacros.Add("Stop Listening", {Suspend-Listening})
    Update-SpeechCommands
}