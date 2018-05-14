function Set-TFSProject{
param([Parameter(position=0)][string] $project)
$script:TFSTeamProject = $project
}Export-ModuleMember -Function Set-TFSProject