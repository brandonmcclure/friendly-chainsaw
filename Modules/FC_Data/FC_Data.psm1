[int]$Script:MaxJobs = 15
[string]$Script:JobPrefix = 'FC_'
[string]$Script:JobsCompleteFlag = "$($Script:JobPrefix)Complete"
$script:SSISLogLevels = @{ "None" = 0; "Basic" = 1; "Performance" = 2; "Verbose" = 3 }

Write-Verbose "Importing Functions"

# Import everything in sub folders folder 
foreach ($folder in @('private','public','classes'))
{
  $root = Join-Path -Path $PSScriptRoot -ChildPath $folder
  if (Test-Path -Path $root)
  {
    Write-Verbose "processing folder $root"
    $files = Get-ChildItem -Path $root -Filter *.ps1


    # dot source each file 
    $files | Where-Object { $_.Name -notlike '*.Tests.ps1' } |
    ForEach-Object { Write-Verbose $_.Name;.$_.FullName }
  }
}
