Function Set-TFSPersonalAccessToken{
param([securestring] $PAT)

$user = ''
$pass = $PAT

$pair = ""

$encodedCreds = 

$basicAuthValue = 

$Headers = @{
    Authorization = $("Basic " +$([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($user):$($PAT | ConvertFrom-SecureString -AsPlainText)"))))
} | ConvertTo-Json -Depth 2 | ConvertTo-SecureString -AsPlainText

$script:AuthHeader = $Headers 

}Export-ModuleMember -Function Set-TFSPersonalAccessToken