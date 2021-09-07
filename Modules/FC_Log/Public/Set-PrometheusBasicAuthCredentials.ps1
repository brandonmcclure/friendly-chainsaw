function Set-PrometheusBasicAuthCredentials{
    param([pscredential]$creds)

    if($null -eq $creds){
        $creds = Get-Credential -Message "enter the basic auth credentials for the prometheus push gateway"
    }

    $script:PrometheusBasicAuthUser = ConvertTo-SecureString -AsPlainText -String $creds.GetNetworkCredential().username | ConvertFrom-SecureString
    $script:PrometheusBasicAuthPassword = ConvertTo-SecureString -AsPlainText -string $creds.GetNetworkCredential().password | ConvertFrom-SecureString
}export-modulemember -function Set-PrometheusBasicAuthCredentials