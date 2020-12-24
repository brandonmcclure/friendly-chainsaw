function convertTo-TimeSpan{
 param([Parameter(ValueFromPipeline)][string[]]$timespanAsString)
 process{
  Write-Output $timespanAsString | select *,@{name='Hour';Expression={$_.Split(":")[0]}},@{name='Minute';Expression={$_.Split(":")[1]}},@{name='Second';Expression={$_.Split(":")[2]}} | Select @{name='lengthTimeSpan';Expression={New-TimeSpan -Hours $_.Hour -Minutes $_.Minute -Seconds $_.Second}}
  }

 }Export-ModuleMember -Function convertTo-TimeSpan