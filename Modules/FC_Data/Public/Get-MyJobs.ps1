function Get-MyJobs {
<#
    .Synopsis
        Returns a list of jobs using the managaed job names.
    .DESCRIPTION
      Returns an array of jobs that have the name like "$Script:JobPrefix*", and the specified status.If no status is specified, returns all jobs. This is used in the FC job framework when polling for finished jobs.  
    .OUTPUTS
       An array of powershell background job objects. or null
    #>
  param([Parameter(Position = 0)] [string[]]$state)

  $returnValue = $null
  if ($state -eq $null) {
    $returnValue = (Get-Job | Where-Object { $_.Name -like "$(Get-JobPrefix)*" })
  }
  else {
    $returnValue = (Get-Job | Where-Object { $state -contains $_.State -and $_.Name -like "$Script:JobPrefix*" })
  }

  Write-Output $returnValue

} Export-ModuleMember -Function Get-MyJobs