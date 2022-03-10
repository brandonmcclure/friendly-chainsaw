$rootPath = '/media/brandon/Main Storage/PA/PortableApps/KeePass/KneePass/'
$dbPath = "/media/brandon/Main Storage/PortableApps/NewDatabase.kdbx"
$keyPath = "$rootPath/NewDatabase.key"

Import-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore, fc_core -force
get-command -module fc_core
Import-module /home/brandon/.local/share/powershell/Modules/SecretManagement.KeePass/SecretManagement.KeePass.psd1
# set up the value for the VaultParameters parameter
$VParams = @{ Path    = $dbPath 

    UseMasterPassword = $true
    KeyPath = $keyPath
    UseMasterKey = $true
}
# Set a vault name and if it exists then unregister that vault in this session
$VaultName = 'KPVault01'
if (Get-SecretVault -Name $VaultName) { Unregister-SecretVault $VaultName }

Register-SecretVault -Name $VaultName -ModuleName SecretManagement.keepass  -VaultParameters $VParams

Get-FCSecret -Name ansible-vault