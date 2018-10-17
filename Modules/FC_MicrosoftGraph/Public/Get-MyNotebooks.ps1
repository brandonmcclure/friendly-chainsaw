		function Get-MyNotebooks{
		[CmdletBinding(SupportsShouldProcess=$true)] 
		Param()
		 
		$BaseURL = Get-MSGraphRestURL
		$action = "/me/onenote/notebooks" 
		$fullURL = $BaseURL + $action
		$authHeader = Get-BearerAuthenticationHeader
		 
		Write-Log "URL we are calling: $fullURL" Debug
		 
		$response = Invoke-RestMethod -uri $fullURL -Method Get -Headers $authHeader | Select -ExpandProperty Value
		 
		Write-Output $response
		} Export-ModuleMember -Function Get-MyNotebooks
