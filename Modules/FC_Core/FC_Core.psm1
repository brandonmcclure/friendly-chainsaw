Write-Verbose "Importing Functions"

# Import everything in sub folders folder 
foreach ($folder in @('Private','Public','Classes'))
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

Write-Verbose -Message 'Exporting Public functions...'
$functions = Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1' -Recurse

Export-ModuleMember -Function $functions.BaseName