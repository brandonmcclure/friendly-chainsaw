function Get-SpeechCommands {
    #.Synopsis
    #  Add one or more commands to the speech-recognition macros, and update the recognition
    #.Parameter CommandText
    #  The string key for the command to remove
    [CmdletBinding()]
    Param()
    $script:SpeechModuleMacros
}Export-ModuleMember -Function Get-SpeechCommands 