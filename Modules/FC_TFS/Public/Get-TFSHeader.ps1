function Get-TFSHeader {
$Header = [System.Collections.Generic.Dictionary`2[System.String,System.String]]::new() 
$auth = ($script:AuthHeader | ConvertFrom-SecureString -AsPlainText | ConvertFrom-Json -Depth 2).Authorization
$Header.Add("Authorization", $auth)
Write-Output $Header
} Export-ModuleMember -function Get-TFSHeader
