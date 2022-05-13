function Get-PrometheusMetricFile{
	param(
		$path
	)
	$cont = Get-Content $path -Raw

	$metrics = @()

	
	$regex = '# HELP(.+?)(?=# HELP|$)'
	$m = [regex]::Matches($cont,$regex, 'SingleLine')
	$matchCount = $m | Measure-Object | select-Object -ExpandProperty Count

	Write-Log "Found $matchCount matches" Debug
	$i=0
	foreach ($match in $m){
		Write-Log "Match #$i" Debug
		$match.Value
		$helpRegex = '# HELP ([a-z_]+) (.+)'
		$m2 = [regex]::Matches($match.Value,$helpRegex)
		$name = $m2.Groups[1].Value
		$description = $m2.Groups[2].Value
		$typeRegex = '# TYPE (.+?) (.+)'
		$m2 = [regex]::Matches($match.Value,$typeRegex)
		if ($m2.Groups[1].Value -ne $name){
			Write-Log "There was an error with the regex" Error -ErrorAction Stop
		}

		$type = $m2.Groups[2].Value
		$valueRegex = "^$name \{(.+)\} (.+)"
		$m2 = [regex]::Matches($match.Value,$valueRegex, 'Multiline')
		$labelString = $m2.Groups[1].Value
		$labelStringColl = $labelString -split ','
		$value = $m2.Groups[2].Value
		$labels = @()
		foreach($t in $labelStringColl){
			$labels += ConvertFrom-StringData -StringData $t
		}
		$metrics += New-Object PSCustomObject -Property @{
			name=$name
			description=$description
			value=$value
			labels=$labels
		}
		$i++

	}
	Write-Output $metrics
}