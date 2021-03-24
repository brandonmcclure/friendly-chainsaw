function Get-AllowedBackupProviders{
	param($name)
	if([string]::IsNullOrEmpty($name)){
		Write-Output $Script:AllowedBackupProviders
		return
	}
	Write-Output $Script:AllowedBackupProviders | where {$_.Name -eq $name}
	}Export-ModuleMember -Function Get-AllowedBackupProviders