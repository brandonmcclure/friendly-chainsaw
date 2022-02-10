function Invoke-PrometheusPushSetup{
    param($pushGatewayURL)
    Add-Type -AssemblyName Prometheus.NetStandard -ErrorAction Stop

    $q = get-content "$env:USERPROFILE\.friendly-chainsaw\secretstore.password" | ConvertTo-SecureString
    Unlock-SecretStore -Password $q -PasswordTimeout 28800
    $creds = Get-Secret -Name "pushgatewayBasicAuth"
    Set-PrometheusBasicAuthCredentials -creds $creds
    Set-PrometheusPushURL -Uri $pushGatewayURL
    $promPusher = Get-PrometheusPusher -scriptName $((Get-PSCallStack | Select-Object -Skip 1 -First 1 | Where-Object { $_.FunctionName -eq '<ScriptBlock>' } | select -ExpandProperty Command) -replace '.ps1','')
    if([string]::IsNullOrEmpty($promPusher)){
        Write-Log "Could not get a Prom Pusher" Error -ErrorAction Stop
    }

    Write-Output $promPusher
}