function Update-SpeechCommands {
    #.Synopsis 
    #  Recreate the speech recognition grammar
    #.Description
    #  This parses out the speech module macros, 
    #  and recreates the speech recognition grammar and semantic results, 
    #  and then updates the SpeechRecognizer with the new grammar, 
    #  and makes sure that the ObjectEvent is registered.
    $choices = New-Object System.Speech.Recognition.Choices
    foreach ($choice in $script:SpeechModuleMacros.GetEnumerator()) {
        New-Object System.Speech.Recognition.SemanticResultValue $choice.Key, $choice.Value.ToString() |
            ForEach-Object { $choices.Add($_.ToGrammarBuilder()) }
    }

    if ($VerbosePreference -ne "SilentlyContinue") {
        $script:SpeechModuleMacros.Keys |
            ForEach-Object { Write-Log "$Computer, $_" }
    }

    $builder = New-Object System.Speech.Recognition.GrammarBuilder 
    $builder.Append((New-Object System.Speech.Recognition.SemanticResultKey ("Commands", $choices.ToGrammarBuilder())))
    $grammar = New-Object System.Speech.Recognition.Grammar $builder
    $grammar.Name = "Power VoiceMacros"

    ## Take note of the events, but only once (make sure to remove the old one)
    Unregister-Event "SpeechModuleCommandRecognized" -ErrorAction SilentlyContinue
    $null = Register-ObjectEvent $grammar SpeechRecognized `
                -SourceIdentifier "SpeechModuleCommandRecognized" `
                -Action {iex $event.SourceEventArgs.Result.Semantics.Item("Commands").Value}

    $global:SpeechModuleListener.UnloadAllGrammars()
    $global:SpeechModuleListener.LoadGrammarAsync($grammar)
}Export-ModuleMember -Function Update-SpeechCommands