function Remove-TFSGitBranch{
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
param([string] $branchName
,[string] $remoteName = 'origin')

$oldLocation = Get-Location
try{
    Set-Location $script:TFSlocalAutoGitRepo
    $result = Start-MyProcess -EXEPath 'git' -options "branch -D $branchName"
    Write-Log $result.stderr
    Write-Log $result.stdout

    $result = Start-MyProcess -EXEPath 'git' -options "push $remoteName --delete $branchName"
    Write-Log $result.stderr
    Write-Log $result.stdout
}
catch{
}
finally{
    Set-Location $oldLocation
}

} Export-ModuleMember -Function Remove-TFSGitBranch