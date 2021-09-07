function Set-PrometheusPushURL{
    param($uri)
    $script:PrometheusPushURL = $uri
}export-ModuleMember -Function Set-PrometheusPushURL