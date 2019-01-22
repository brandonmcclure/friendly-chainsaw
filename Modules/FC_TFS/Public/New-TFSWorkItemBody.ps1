
function New-TFSWorkItemBody{
param($fieldDefinition,[string] $fieldDefinitionpath)

function AmmendCommasOnWorkItemBody{
param($workItemBody)
if($workItemBody -eq @"
[
"@){
    return ""
}
else{
    return ","
}
}


$config = Get-Content $fieldDefinitionpath | ConvertFrom-Json
$workItemBody = @"
[
"@

foreach ($field in $fieldDefinition.keys){
    if($field -notin $config.FieldAlias){
        Write-Log "Could not find a field with the name: $($field)" Error -ErrorAction Stop
    }

    $fieldReference = $config | where {$field -in $_.FieldAlias}| select -ExpandProperty FieldPath

    $workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
    {
        "op": "add",
        "path": "/fields/$fieldReference",
        "value": "$($fieldDefinition[$field])"
    }
"@
}

$workItemBody += @"

]

"@

Write-Output $workItemBody
}Export-ModuleMember -Function New-TFSWorkItemBody