Import-Module FC_Core -Force;
$VerbosePreference = "Ignore"
try{
    $stderrDel = {
        Write-Host "$($Event.SourceIdentifier) $($Event.SourceEventArgs.Data)"
    }
    $stdoutDel = {
        Write-Host "$($Event.SourceIdentifier) $($Event.SourceEventArgs.Data)"
    }
 $p = Start-MyProcess -EXEPath 'C:\Users\bmcclure\AppData\Local\prometheus\prometheus.exe' -options "--config.file=`"C:\Users\bmcclure\AppData\Local\prometheus\localwindows_exporter.prometheus.yml`"" -logLevel debug -async -stderrdelegate $stderrDel -stdOutdelegate $stdoutDel

 $t = $true
 do
{
Start-Sleep -Seconds 5
$t = $false

}
while ($t)
}
catch{
    throw
}
finally{
    Write-Log "Stopping Processes"
    foreach ($i in ($p | Select Name,@{name='mytype'; Expression={$_.pstypenames[0]}} | where {$_.mytype -like 'System.Management.Automation.PSEventJob*'})){
        Write-Verbose "Unregistering event: $($i.Name)"
        Unregister-Event -SourceIdentifier $i.Name
    }
    foreach ($i in ($p | Select id,@{name='mytype'; Expression={$_.pstypenames[0]}} | where {$_.mytype -like 'System.Diagnostics.Proces*'})){
        Write-Verbose "stopping process: $($i.id)"
        Stop-Process -Id $($i.id) -Verbose
    }
    Write-Host "All Done"
}