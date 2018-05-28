function Set-TFSBaseURL{
param([Parameter(position=0)][string] $url)
$script:TFSbaseURL = $url
}Export-ModuleMember -Function Set-TFSBaseURL