

Function Get-StringPermutation {
    <#
        .SYNOPSIS
            Retrieves the permutations of a given string. Works only with a single word.
 
        .DESCRIPTION
            Retrieves the permutations of a given string Works only with a single word.
       
        .PARAMETER String           
            Single string used to give permutations on
       
        .NOTES
            Name: Get-StringPermutation
            Author: Boe Prox
            DateCreated:21 Feb 2013
            DateModifed:21 Feb 2013
 
        .EXAMPLE
            Get-StringPermutation -String "hat"
            Permutation                                                                          
            -----------                                                                          
            hat                                                                                  
            hta                                                                                  
            ath                                                                                  
            aht                                                                                  
            tha                                                                                  
            tah        

            Description
            -----------
            Shows all possible permutations for the string 'hat'.

        .EXAMPLE
            Get-StringPermutation -String "help" | Format-Wide -Column 4            
            help                  hepl                  hlpe                 hlep                
            hpel                  hple                  elph                 elhp                
            ephl                  eplh                  ehlp                 ehpl                
            lphe                  lpeh                  lhep                 lhpe                
            leph                  lehp                  phel                 phle                
            pelh                  pehl                  plhe                 pleh        

            Description
            -----------
            Shows all possible permutations for the string 'hat'.
 
    #>
    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipeline=$True)]
        [string]$String = 'the'
        ,[int]$Size = 0
    )
    Begin {
        #region Internal Functions
        Function New-Anagram { 
            Param([int]$NewSize)              
            If ($NewSize -eq 1) {
                return
            }
            For ($i=0;$i -lt $NewSize; $i++) { 
                New-Anagram  -NewSize ($NewSize - 1)
                If ($NewSize -eq 2) {
                    New-Object PSObject -Property @{
                        Permutation = $stringBuilder.ToString()                  
                    }
                }
                Move-Left -NewSize $NewSize
            }
        }
        Function Move-Left {
            Param([int]$NewSize)        
            $z = 0
            $position = ($Size - $NewSize)
            [char]$temp = $stringBuilder[$position]           
            For ($z=($position+1);$z -lt $Size; $z++) {
                $stringBuilder[($z-1)] = $stringBuilder[$z]               
            }
            $stringBuilder[($z-1)] = $temp
        }
        #endregion Internal Functions
    }
    Process {
        if ($Size -eq 0 ){
            $Size = $String.length
        }
        $stringBuilder = New-Object System.Text.StringBuilder -ArgumentList $String
        New-Anagram -NewSize $Size
    }
    End {}
}

Set-logTargets -Speech 0
Set-LogFormattingOptions -PrefixTimestamp 1 -PrefixCallingFunction 1 -AutoTabCallsFromFunctions 1
Set-LogLevel Info
$anagrams = @("urwimdoootevnahyy")
$dictionaryPath = "E:\Git\friendly-chainsaw\words_dictionary_withCharCount.json"
$wordMeta = @{1=3;2=4;3=2;4=4;5=2;6=2;}
if($wordMeta[1] -eq 0){
    $minLength = $anagrams | select -ExpandProperty Length | sort | select -First 1
    $maxLength = $anagrams | select -ExpandProperty Length | sort -Descending | select -First 1
    $wordMeta[1] = $maxLength
}
else{
$minLength = $wordMeta.Values | sort | select -First 1
$maxLength = $wordMeta.Values | sort -Descending | select -First 1
}

write-Log "Loading main dictionary" Verbose
if ($script:Dictionary -eq $null){
    $dictionary = (Get-Content $dictionaryPath -Raw | ConvertFrom-Json) 
    $script:Dictionary = $dictionary
}
else{
    $dictionary = $script:Dictionary | where {$_.Length -ge $minLength -and $_.Length -le $maxLength}
}
$dictionaryCount = $dictionary | Measure-Object | select -ExpandProperty count
if ($dictionaryCount -eq 0 ){
    Write-Log "There was an error loading the dictionary at $dictionaryPath" Error -ErrorAction Stop
}
write-Log "Done Loading main dictionary. Loaded $dictionaryCount words with a length between $minLength and $maxLength" Verbose
$wordResults = @()
$script:filteredDictionaries = @()
  foreach($word in $wordMeta.Values){

        Write-Log "Filtering dictionary for this word" Verbose
            Write-Log "Filtering main data base and saving to memory" Verbose
            $filteredDictionary = $dictionary | where {$_.Length -eq $word} | select -ExpandProperty Name -Unique
            $dict = new-object psobject
            $dict | Add-Member -type NoteProperty -Name length -Value $word
            $dict | Add-Member -type NoteProperty -Name dictionary -Value $filteredDictionary  | select -ExpandProperty Name -Unique
            $script:filteredDictionaries += $dict
        Write-Log "Done Filtering dictionary for this word" Verbose
foreach ($string in $anagrams){
Write-Log "Checking for $string"

$outObj = New-Object PSObject
$outObj | Add-Member -type NoteProperty -Name "StringName" -Value $string
$outObj | Add-Member -type NoteProperty -Name "words"  -Value @()

        $permiations = Get-StringPermutation -String $string | select -ExpandProperty Permutation | foreach {$_.Substring(0,$word)} | select -Unique

        Write-Log "Found $($permiations | Measure-Object | Select-Object -ExpandProperty Count) permiations of $string" verbose
        
        $calls = @()
                                        foreach ($perm in $permiations){

        Write-Log "Checking for $perm in dictionary" Debug
        if ($perm -in $filteredDictionary){
            Set-logTargets -Speech 1
            Write-Log "Found real word: $($dictionary |where Name -eq $perm | select -ExpandProperty Name )"
            $outObj.words += $perm;
            Set-logTargets -Speech 0
        }
        Write-Log "done checking dictionary" Verbose
        }

        $wordResults += $outObj
    }
}

$stringResults | ft