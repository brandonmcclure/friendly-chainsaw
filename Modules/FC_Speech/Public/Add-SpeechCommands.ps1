function Add-SpeechCommands {
    #.Synopsis
    #  Add one or more commands to the speech-recognition macros, and update the recognition
    #.Parameter CommandText
    #  The string key for the command to remove
    [CmdletBinding()]
    Param([hashtable]$VoiceMacros,[string]$Computer=$Script:SpeechModuleComputerName)

    ## Add the new macros
    $script:SpeechModuleMacros += $VoiceMacros 
    ## Update the default if they change it, so they only have to do that once.
    $script:SpeechModuleComputerName = $Computer 
    Update-SpeechCommands
}Export-ModuleMember -Function Add-SpeechCommands 