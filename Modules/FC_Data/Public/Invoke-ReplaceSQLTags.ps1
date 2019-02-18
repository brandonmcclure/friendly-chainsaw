function Invoke-ReplaceSQLTags{
param($tagInfoObject,[switch] $replaceWithSubquery,[string] $replaceFile)

$startTagValue = "--<<$($tagInfoObject.TagName)_Start>>"
$endTagValue = "--<<$($tagInfoObject.TagName)_End>>"
$regex = "(?s)($($startTagValue.Replace("-","\-"))){1}.+?($($endTagValue.Replace("-","\-"))){1}"
$targetSQL = Get-Content $replaceFile -Raw

if($replaceWithSubquery){
    $replaceWith =$startTagValue + "`r`n--SQL between these tags was inserted from $($tagInfoObject.ReplaceFile) on : $(Get-Date)`r`n("+( get-content $tagInfoObject.ReplaceFile -raw)+")" + "`r`n" + $endTagValue
}
else{
    $replaceWith =$startTagValue +"`r`n"+$tagInfoObject.RawSQL + "`r`n" + $endTagValue
}

if($targetSQL -inotmatch $regex){
    Write-Log "Could not find a match for the tags"
    return
}

$replacedSQL = $targetSQL -replace $regex,$replaceWith

Set-Content -Path $replaceFile -Value $replacedSQL.Trim()


}export-modulemember -function Invoke-ReplaceSQLTags