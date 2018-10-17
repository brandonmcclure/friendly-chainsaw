		function Get-BearerAuthenticationHeader{
		 [CmdletBinding(SupportsShouldProcess=$true)] 
		param()
		if ([string]::IsNullOrEmpty($global:msGraphToken)){
    $client_id = "00d16af4-d0c7-460a-a9dc-fd350eb4b100"
    $redirect_uri = 'https://localhost/'#"urn:ietf:wg:oauth:2.0:oob"
            $myToke = Get-GraphOauthAccessToken -Client_Id $client_id -Redirect_uri $redirect_uri -Resource (Get-MSGraphRestURL)
            $myCode = Get-GraphOauthAuthorizationCode -client_id $client_id -redirect_uri $redirect_uri -Resource (Get-MSGraphRestURL)
		 $global:msGraphToken =  Get-MSALToken -Scopes "Notes.Read","Files.Read" -ClientId $client_id -RedirectUri  | Select -ExpandProperty AccessToken
		}
		$authHeader = @{
		    "Authorization" = ("Bearer {0}" -f $global:msGraphToken);
		    "Content-Type" = "application/json";
		}
		 
		Write-Output $authHeader
} Export-ModuleMember -Function Get-BearerAuthenticationHeader