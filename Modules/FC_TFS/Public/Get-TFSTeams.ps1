function Get-TFSTeams{
<#
    .Synopsis
      Please give your script a brief Synopsis,
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       What sort of pipeline inputdoes this expect?
    .OUTPUTS
       What sort of pipeline output does this output?
    .LINK
       www.google.com
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][string] $userAccountName)

#No REST endpoint for user IDs. Have to query the DB https://social.msdn.microsoft.com/Forums/vstudio/en-US/1b08388b-5dad-4235-9071-3e0a7452851b/tfs-rest-api-where-can-i-get-the-ids-for-usersgroups-to-use-in-rest-api-calls?forum=tfsgeneral
$response = Invoke-Sqlcmd -ServerInstance "Vwehstfssql02" -Database 'Tfs_Configuration' -Query "select Id from [dbo].[tbl_Identity] where AccountName = '$userAccountName'" | Select -ExpandProperty Id | Select -ExpandProperty Guid

write-Output $response

} Export-ModuleMember -Function Get-TFSTeams