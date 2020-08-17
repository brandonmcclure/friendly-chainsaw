FUNCTION Invoke-AzureDevops_LinkWIQLResultsToParentWorkItem{
<#
    .Synopsis
      Will create a parent link from all work items returned from a flat wiql query to the specified $ParentWorkItemID
    .EXAMPLE
        RUn with the WhatIf switch to see which work items will ge updated:
        Right guard project
            WIQL Swivel - Right Guard
        Invoke-AzureDevops_LinkWIQLResultsToParentWorkItem -ParentWorkItemID 11111 -Query "Select [System.ID] from workItems where [System.ID] = '2222'" -WhatIF
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "info"
,[switch] $winEventLog
,[string] $PAT
,[string] $ParentWorkItemID = $null
         ,   $query = @"
SELECT
    [System.Id],
    [System.WorkItemType],
    [System.Title],
    [System.AssignedTo],
    [System.State],
    [System.Tags]
FROM workitems
WHERE
    [System.Id] = '35194'
"@)

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
if($winEventLog){Set-logTargets -WindowsEventLog 1}
Set-LogFormattingOptions -PrefixCallingFunction 1 -AutoTabCallsFromFunctions 1

if([string]::IsNullOrEmpty( $ParentWorkItemID)){
    Write-Log "Please pass a value to $ParentWorkItemID"
}
Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug

Set-TFSAPIVersion -apiVersion 5.0
Set-TFSBaseURL 'https://dev.azure.com/DenverHealth-EpicCogito'
Set-TFSCollection 'Epic'
$epicProject = 'Epic'
Set-TFSProject $epicProject
Set-TFSWITFieldDefinition "C:\Source\TFS\Caboodle\TFS Work Item Customizations\POSHFriendlyFieldDefinition.json"

$myConfig = Get-Content "$env:USERPROFILE\Cogito\MyRecurringWorkItems.json" | ConvertFrom-Json

#Check the configuration for a SecureString PAT to use.
if ([bool]($myConfig.PSobject.Properties.name -match "SecurePAT")){
$securePAT = $myConfig.SecurePAT | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePAT)
$PAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
}
if([string]::IsNullOrEmpty($PAT)){
    Write-Log "You must pass a PAT" Error -ErrorAction Stop
}
Set-TFSPersonalAccessToken $PAT

 $parentPBIURL = "https://dev.azure.com/DenverHealth-EpicCogito/Epic/_apis/wit/workItems/$ParentWorkItemID"
            
        if ([string]::IsNullOrEmpty($parentPBIURL)){
               Write-Log "I am programmed to create tasks which are children of a PBI and I do not know which PBI to create this task for!!!" Error -ErrorAction Stop  
        }
              $restBody = New-TFSWorkItemBody -itemDefinition @{
relationship_parent=$($parentPBIURL.Replace("\","\\"));
}
    

$repoName = "Caboodle"
$repoObj = Get-TFSRepositories -repositoryName $repoName 

            #CheckForExistingPBI in this sprint

            $repoObj = $repoObj  | Get-TFSWIQLQueryResults -query $query
            $childWorkItems = $repoObj.QueryResults | where {$_.QueryText -eq $query} | select -ExpandProperty QueryResult | select -ExpandProperty workItems
            foreach ($wi in $childWorkItems){
                Write-Log "workItem: $($wi.id)"
                if($WhatIfPreference){
                    Write-Log "Would update work item: $($wi.id) to be a child of $ParentWorkItemID"
                }
                else{
                    $repoObj | Update-TFSWorkItem -requestBody $restBody -Id $wi.id
                }
            }
            
           
           
     

            

Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
}Export-ModuleMember -Function Invoke-AzureDevops_LinkWIQLResultsToParentWorkItem