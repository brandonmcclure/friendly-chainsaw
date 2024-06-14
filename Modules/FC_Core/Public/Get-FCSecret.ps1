function Get-FCSecret{
    param($Name,[int]$ClipboardTime = 10,$vaultName = $null)

    if([string]::IsNullOrEmpty($Name)){
        Write-Log "You must pass a value to the name parameter" Error -ErrorAction Stop
    }
    Get-Secret -Name $Name -Vault $vaultName -AsPlainText -ErrorAction Stop | set-Clipboard; 
    foreach($i in 1..$ClipboardTime){
        
        write-Host $("."*$i);Start-Sleep 1
    }
    set-Clipboard "garbage";
}