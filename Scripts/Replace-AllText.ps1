$textToFind = 'something'
$textToReplace = 'somethingElse'
$SearchExtensionList = @(".md",".sql",".ps1",".conmgr",".cs",".json",".csv",".yaml",".yml",".odc",".txt")

$configFiles = Get-ChildItem 'E:\Source\Auto' -Recurse -File | where {$_.Extension -in $SearchExtensionList}

$fileCOunt = $configFiles | Measure-Object | Select -ExpandProperty Count
$i = 0
Write-Host "Looping over $fileCount files"
$myMatches = @()
foreach ($file in $configFiles)
{
    $pct = ($i /$fileCOunt)*100.00
    Write-Progress -Activity "Search in Progress" -Status "$($pct)% Complete:" -PercentComplete $pct;
    $cont = (Get-Content -path $file.FullName -Raw ) 

    if ($cont -match $textToFind){
        $myMatches += $file.FullName
        $cont = $cont | Foreach-Object { $_ -replace $textToFind, $textToReplace } 

        $cont | Set-Content $file.FullName -NoNewline -Force
    } 
    $i++
}

Write-Log "We found $($myMatches | Measure-Object | select -ExpandProperty Count) matches"

$myMatches