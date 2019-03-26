Function Set-TFSAPIVersion{
param([ValidateSet("3.0","4.1","4.1-preview.1","5.0")][Parameter(position=0)][string] $apiVersion)
Write-Log "Setting API version to: $apiVersion" Debug
$script:apiVersion = $apiVersion

}Export-ModuleMember -Function Set-TFSAPIVersion