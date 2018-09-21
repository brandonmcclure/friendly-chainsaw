function Request-JobStatus {
<#
    .Synopsis
       Used to poll the Powershell Jobs running under the current script scope. Will Write-Log the results from completed jobs, and then remove them. Will return $true when there are no more jobs.  
    .DESCRIPTION
       
    .EXAMPLE
        The below code will check the jobs every 15 seconds untill all the running jobs have completed. 
        $jobPollTime = 15
       $exit = $false
        while ($exit -eq $false){
            $exit = Check-JobStatus
            sleep $jobPollTime       
        }
    #>
  param([string]$nameLike = $null
    ,[switch]$clearFailed)

  $results = $null
  if ([string]::IsNullOrEmpty(($nameLike))) {
    $jobs = Get-Job | Where-Object { $_.Name -like "$($Script:JobPrefix)$nameLike*" }
    $compJobs = $jobs | Where-Object State -EQ "Completed"
  }
  else {
    $jobs = Get-Job | Where-Object { $_.Name -like "$($Script:JobPrefix)$nameLike*" }
    $compJobs = $jobs | Where-Object { $_.State -eq "Completed" }
  }

  Write-Log "[Request-JobStatus]     $($jobs.Count) Jobs have not been recieved. $($compJobs.Count) Jobs have been completed and will be recieved." Debug
  if ($($jobs.count) -eq 0) {
    $results = Get-JobsCompleteFlag
  }
  if ($clearFailed) {
    $failedJobs = $jobs | Where-Object { $_.State -eq "Failed" }
    Write-Log "[Request-JobStatus]     Clearing $($failedJobs.Count) jobs that have failed" Debug
    foreach ($job in $failedJobs) {
      $job | Remove-Job
    }
  }
  if ($jobs.count -eq 0) {
    Write-Log "[Request-JobStatus]     All jobs complete" Debug
    $results = Get-JobsCompleteFlag
  }
  foreach ($job in $compJobs) {
    Write-Log "[Request-JobStatus]     ----------" Debug
    Write-Log "[Request-JobStatus]     Recieving job: $($job.Name)" Debug
    $results = $job | Receive-Job
    $job | Remove-Job
  }

  Write-Output $results
} Export-ModuleMember -Function Request-JobStatus