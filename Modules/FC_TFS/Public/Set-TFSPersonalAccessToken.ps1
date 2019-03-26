Function Set-TFSPersonalAccessToken{
param([string] $PAT)

$user = ''
$pass = $PAT

$pair = "$($user):$($pass)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

$script:AuthHeader = $Headers

}Export-ModuleMember -Function Set-TFSPersonalAccessToken