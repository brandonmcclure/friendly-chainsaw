function New-GitBranch{
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
param([string] $branchName)

$oldLocation = Get-Location
try{
    Set-Location $script:TFSlocalAutoGitRepo
    if ((Get-GitBranch) -ne 'master'){
        Sync-TFSLocalAutoRepo
    }

    & git checkout -b $branchName
    & git push --set-upstream origin $branchName

}
catch{
    Set-Location $oldLocation
}
finally{
    Set-Location $oldLocation
}

} Export-ModuleMember -Function New-TFSGitBranch