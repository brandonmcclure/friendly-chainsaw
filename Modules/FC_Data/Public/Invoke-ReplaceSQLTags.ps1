function Invoke-ReplaceSQLTags{
<#
    .Synopsis
      I wrote this to simplify some complex stored procedures that I was writing. The sprocs needed to union data from several tables into a unified model. as such, I needed all of my subqueries to have the right number/type of columns, and I wanted the ability to develop/test each subquery seperatly. Using these tags allows me to develop the subqueries as seperate files, run this code to put them in a test harness as I am working on individual queries, then le the stored proc get the bulk of it's code generated
    #>
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
    Write-Log "Could not find a match for the tags" Verbose
    return
}
Write-Log "Replacing the tag: $($tagInfoObject.tagName)"
$replacedSQL = $targetSQL -replace $regex,$replaceWith

Set-Content -Path $replaceFile -Value $replacedSQL.Trim()


}export-modulemember -function Invoke-ReplaceSQLTags