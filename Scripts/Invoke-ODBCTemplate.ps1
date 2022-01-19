<#
    .Synopsis
      Use this template to persist ODBC connections to source code. You will need to run/automate the cannonical version of this template that you create. 
    #>
param($namePrefix = "",
$DsnType = 'System', # User or System
[switch]$Check = $true,
[switch]$Add,
[switch]$Remove
)
#Use Get-OdbcDriver to see what values you can specify for DriverName

$Options = @(
    @{Name="$($namePrefix)database1"
    DriverName = "ODBC Driver 13 for SQL Server"
    DsnType = $DsnType
    Platform = "32-bit"
    SetPropertyValue = @("Server=Localhost", "Trusted_Connection=Yes", "Database=database1")
    },
    @{Name="$($namePrefix)Database2"
    DriverName = "ODBC Driver 13 for SQL Server"
    Platform = "64-bit"
    DsnType = $DsnType
    SetPropertyValue = @("Server=localhost", "Trusted_Connection=Yes", "Database=Database2")
    }
)

if($Check){
    foreach ($opt in $options){
        Write-Log "Checking for ODBC DSN with name $($opt.Name)"
        Get-OdbcDsn -Name $opt.Name
    }
}

if($Add){
    foreach ($opt in $options){
        Write-Log "Adding Odbc DSN named $($opt.Name)"
        Add-OdbcDsn @opt
    }
}
if($Remove){
    foreach ($opt in $options){
        Write-Log "Removing Odbc DSN named $($opt.Name)"
        Remove-OdbcDsn -name $opt.Name -DsnType $opt.DsnType -DriverName $opt.DriverName
    }
}