$minBetweenExec = 1
while($true){
    . "$PSScriptRoot\PrometheusBatchExample.ps1"
    sleep ($minBetweenExec*60)
    . "$PSScriptRoot\PrometheusBatchExample2.ps1"
    sleep ($minBetweenExec*60)
    . "$PSScriptRoot\PrometheusBatchExample3.ps1"
    sleep($minBetweenExec*60)
}