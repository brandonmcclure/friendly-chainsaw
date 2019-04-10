
function New-TFSWorkItemBody{
param($itemDefinition)

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

$workItemBody = @"
[
"@

foreach ($field in $itemDefinition.keys){
    if($field -notin $script:fieldDefinition.FieldAlias){
        Write-Log "Could not find a field with the name: $($field)" Error -ErrorAction Stop
    }

    

    $fieldReference = $script:fieldDefinition | where {$field -in $_.FieldAlias}| select -ExpandProperty FieldPath

    if($field -eq "relationship_parent"){
     $workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
{
            "op": "add",
            "path": "/relations/-",
            "value":
            {
                "rel": "System.LinkTypes.Hierarchy-Reverse",
                "url": "$($itemDefinition[$field])",
                "attributes":
                {
                    "isLocked": false,
                "comment": "Automagical relationship"
                }
            }
        }
"@
        continue;
    }
    $workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
    {
        "op": "add",
        "path": "/fields/$fieldReference",
        "value": "$($itemDefinition[$field])"
    }
"@
}

$workItemBody += @"

]

"@

Write-Output $workItemBody
}Export-ModuleMember -Function New-TFSWorkItemBody