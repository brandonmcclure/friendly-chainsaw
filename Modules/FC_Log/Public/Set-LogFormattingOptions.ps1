function Set-LogFormattingOptions{
    param([int] $PrefixCallingFunction = -1,[int] $AutoTabCallsFromFunctions = -1,[int] $PrefixTimestamp = -1)

    if ($PrefixCallingFunction -eq 1 -or $PrefixCallingFunction -eq 0){
        $script:logFormattingOptions['PrefixCallingFunction'] = $PrefixCallingFunction
    }
    if ($AutoTabCallsFromFunctions -eq 1 -or $AutoTabCallsFromFunctions -eq 0){
        $script:logFormattingOptions['AutoTabCallsFromFunctions'] = $AutoTabCallsFromFunctions
    }
    if ($PrefixTimestamp -eq 1 -or $PrefixTimestamp -eq 0){
        $script:logFormattingOptions['PrefixTimestamp'] = $PrefixTimestamp
    }
}export-modulemember -Function Set-LogFormattingOptions