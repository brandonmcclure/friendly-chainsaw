function Set-TFSCollection{
param([Parameter(position=0)][string] $collection)
$script:TFSCollection = $collection
}Export-ModuleMember -Function Set-TFSCollection