<#
        .SYNOPSIS
            Retrieves the permutations of a given string. Works only with a single word.
 
        .DESCRIPTION
            Retrieves the permutations of a given string Works only with a single word.
       
https://github.com/hghyug/english-words/raw/main/words_dictionary.json
#>
param(
	$wordLength = 5,
	[bool]$resetDictionary ,
	$forceStartWord = "SHIST"
)
$dictionaryPath = "$PSScriptRoot\words_dictionary.txt"
$CompletedWordlePath = "$PSScriptRoot\completedWordle.json"
$invalidWorldListPath = "$psscriptRoot\invalidWords.txt"


Set-LogLevel "Verbose"
Write-Log "Checking if the $dictionaryPath exists"
if (-not (Test-Path $dictionaryPath)){
	Write-Log "Downloading the dictionary file"
	Invoke-WebRequest -URI "https://github.com/dwyl/english-words/raw/master/words_alpha.txt" -OutFile $dictionaryPath
}

write-Log "Loading main dictionary" Verbose

function Invoke-DictionaryLoad{
	if ($script:Dictionary -eq $null -or $resetDictionary){
		$script:Dictionary = Get-Content $dictionaryPath | where {$_.Length -ge $wordLength -and $_.Length -le $wordLength}
	}

	$completedWordles = Get-Content $CompletedWordlePath | ConvertFrom-Json
	$invalidWords = Get-Content $invalidWorldListPath | where {$_.Length -ge $wordLength -and $_.Length -le $wordLength}
	$invalidWordCount = $invalidWords | Measure-Object | Select-Object -ExpandProperty Count 
	Write-Log "invalidWordCount: $invalidWordCount"
	$dictionary = $script:Dictionary | where {$_ -notin $invalidWords}

	$dictionaryCount = $dictionary | Measure-Object | select -ExpandProperty count
if ($dictionaryCount -eq 0 ){
    Write-Log "There was an error loading the dictionary at $dictionaryPath" Error -ErrorAction Stop
}
write-Log "Done Loading main dictionary. Loaded $dictionaryCount words with a length between $minLength and $maxLength"
}
$letterArrayColl = @()
function Invoke-LoopyWord{
	param(
		$wordLength,
		$filteredDic,
		$correctLetterArray
	)
	foreach($i in (0..$wordLength)){
		if($correctLetterArray[$i] -in @('*','~')){
			continue
		}
		try{
			$filteredDic = $filteredDic | where {$_.ToCharArray()[$i] -eq $correctLetterArray[$i]}
		}
		catch{
			throw
		}
		$filteredDicCount = $filteredDic | Measure-Object | Select-Object -ExpandProperty count
		Write-Log "On iteration $i, there are $($filteredDicCount) words that this could be"
		Write-Output $filteredDic
	}
}
function Get-Word{
	param(
		$CorrectLetterArray
	)
	if([string]::IsNullOrEmpty($CorrectLetterArray)){
		$dictionaryCount = $script:Dictionary | Measure-Object | Select-Object -ExpandProperty Count
		$outVal = ""
		if([string]::IsNullOrEmpty($letterArrayColl)){
			$outVal = $script:Dictionary[$(Get-Random -minimum 0 -Maximum $dictionaryCount)]
		}else{
			$filteredDic = $script:Dictionary
			foreach($i in $letterArrayColl){
				$filteredDic = Invoke-LoopyWord -wordLength $wordLength -correctLetterArray $i -filteredDic $filteredDic
			}
			$outVal = $filteredDic[$(Get-Random -minimum 0 -Maximum $filteredDicCount)]
		}
		Write-Output $outVal
	}
	else{
		$letterArrayColl += $CorrectLetterArray
		$outVal = ""
		$filteredDic = Invoke-LoopyWord -wordLength $wordLength -correctLetterArray $CorrectLetterArray -filteredDic $script:Dictionary
		$script:Dictionary = $filteredDic
		$filteredDicCount = $filteredDic | Measure-Object | Select-Object -ExpandProperty count
		$outVal = $filteredDic[$(Get-Random -minimum 0 -Maximum $filteredDicCount)]
		Write-Output $outVal
	}
}


Invoke-DictionaryLoad
$inPlay = $true
$i = 0
$correctChars = @()
while ($inPlay){
	if($i -eq 0 -and -not [string]::IsNullOrEmpty($forceStartWord)){
		$word = $forceStartWord
	}else{
		$word = Get-Word -CorrectLetterArray $correctChars
	}
	$correctChars = $null
	Write-Log "Try the word: $word"
	$result = Read-Host "Which letters worked? Use an * to indicate miss; ~ to indicate wrong location; and a single ! to indicate that the word is not valid"

	if([string]::IsnullOrEmpty($result)){
		Write-Log "Invalid selection!"
	}
	elseif ($result -eq '!'){
		Write-Log "Adding $word to the invalid word list"
		"`r`n$word" | add-content -Path $invalidWorldListPath
		Invoke-DictionaryLoad
	}
	elseif ($result -eq '@'){
		Write-Log "Grabbing another word"
		continue;
	}
	elseif($result.Length -ne $wordLength){
		Write-Log "You need to specify a word with the length $wordLength"
	}
	elseif([string]::IsNullOrEmpty(($result.ToCharArray() | Where-Object {$_ -eq '*' -or $_ -eq '~'}) )){
		Write-Log "Completion event" Debug
		$completedWordles += @{word=$word; date=$(Get-Date)}
		$completedWordles | ConvertTo-Json | Set-Content $CompletedWordlePath
		$inPlay = $false
	}
	else{
		$correctChars = $result.ToCharArray()
	}
	$i++
}

Write-Log "You have completed the Wordle!"