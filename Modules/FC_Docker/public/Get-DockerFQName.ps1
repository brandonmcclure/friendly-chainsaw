function Get-DockerFQName{
    <# 
.SYNOPSIS 
    Use this to get an object of type DockerFQName. This method does not require you to have a "using" statement in your calling scripts
.OUTPUTS 
    [DockerFQName]
#>
param($Registry,$Repository,$Image,$Tag)
    Write-Output $(New-Object DockerFQName -ArgumentList @($Registry,$Repository,$Image,$Tag))
}Export-ModuleMember -Function Get-DockerFQName 