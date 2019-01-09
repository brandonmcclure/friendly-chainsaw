
function New-TFSWorkItemBody{
param([string]$workItemTitle,$AssignedTo,$IterationPath,$AreaPath,$itemType)

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
if (-not [string]::IsNullOrEmpty($workItemTitle)){
$workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
    {
        "op": "add",
        "path": "/fields/System.Title",
        "value": "$($workItemTitle)"
    }
"@
}
if (-not [string]::IsNullOrEmpty($AssignedTo)){
$workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
    {
        "op": "add",
        "path": "/fields/System.AssignedTo",
        "value": "$($AssignedTo)"
    }
"@
}
if (-not [string]::IsNullOrEmpty($IterationPath)){
$workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
    {
        "op": "add",
        "path": "/fields/System.IterationPath",
        "value": "$($IterationPath)"
    }
"@
}
if (-not [string]::IsNullOrEmpty($AreaPath)){
$workItemBody += @"
$(AmmendCommasOnWorkItemBody $workItemBody)
    {
        "op": "add",
        "path": "/fields/System.AreaPath",
        "value": "$($AreaPath)"
    }
"@
}
$workItemBody += @"

]

"@

Write-Output $workItemBody
}Export-ModuleMember -Function New-TFSWorkItemBody