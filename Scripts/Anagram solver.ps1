

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
        $size = $String.length
        $stringBuilder = New-Object System.Text.StringBuilder -ArgumentList $String
        New-Anagram -NewSize $Size
    }
    End {}
}

Set-logTargets -Speech 0
Set-LogFormattingOptions -PrefixTimestamp 1 -PrefixCallingFunction 1 -AutoTabCallsFromFunctions 1
Set-LogLevel verbose
$anagrams = @("grihas","spogsi","fruuet","luteml","tryhow")
$minLength = 10
$maxLength = 0
foreach ($a in $anagrams)
{
    if ($a.length -lt $minLength){$minLength = $a.Length}
    if ($a.length -gt $maxLength){$maxLength = $a.Length}
}
write-Log "Loading dictionary" Verbose
$dictionary = (Get-Content C:\Users\brandon\Downloads\words_dictionary.json -Raw | ConvertFrom-Json) | where {$_.Length -ge $minLength -and $_.Length -le $maxLength}
$dictionaryCount = $dictionary | Measure-Object | select -ExpandProperty count
write-Log "Done Loading dictionary. Loaded $dictionaryCount words with a length between $minLength and $maxLength" Verbose
$stringResults = @()
foreach ($string in $anagrams){
Write-Log "Checking for $string"
$outObj = New-Object PSObject
$outObj | Add-Member -type NoteProperty -Name "StringName" -Value $string
$outObj | Add-Member -type NoteProperty -Name "anagramMatches"  -Value @()

$APIThrottlePerMinute = 60

$permiations = Get-StringPermutation -String $string

Write-Log "Found $($permiations | Measure-Object | Select-Object -ExpandProperty Count) permiations of $string" verbose
Write-Log "Filtering dictionary for this word" Verbose
$filteredDictionary = $dictionary | where {$_.Length -eq $string.Length} | select -ExpandProperty Name

$calls = @()
foreach ($perm in $permiations | select -ExpandProperty Permutation){

    Write-Log "Checking for $perm in dictionary" Debug
    if ($perm -in $filteredDictionary){
        Set-logTargets -Speech 1
        Write-Log "Found real word: $($dictionary |where Name -eq $perm | select -ExpandProperty Name )"
        $outObj.anagramMatches += $perm
        Set-logTargets -Speech 0
    }
    Write-Log "done checking dictionary" debug
}

$stringResults += $outObj
}

$stringResults | ft