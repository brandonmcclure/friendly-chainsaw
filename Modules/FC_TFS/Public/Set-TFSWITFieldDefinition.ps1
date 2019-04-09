Function Set-TFSWITFieldDefinition{
param([string] $fieldDefinitionPath)

$script:fieldDefinition = Get-content $fieldDefinitionPath | ConvertFrom-Json 

}Export-ModuleMember -Function Set-TFSWITFieldDefinition