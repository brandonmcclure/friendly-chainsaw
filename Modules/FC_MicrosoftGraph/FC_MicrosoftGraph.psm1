$script:MSGraphBaseURL = "https://graph.microsoft.com"
$script:apiVersion = 'v1.0'
$script:msGraphToken = 'pvkFSHLLotliGU23557]^(]'

# Import everything in sub folders folder 
foreach ( $folder in @( 'private', 'public', 'classes' ) ) 
{ 
    $root = Join-Path -Path $PSScriptRoot -ChildPath $folder 
    if ( Test-Path -Path $root ) 
    { 
        Write-Verbose "processing folder $root" 
        $files = Get-ChildItem -Path $root -Filter *.ps1 
 
 
         # dot source each file 
         $files | where-Object { $_.name -NotLike '*.Tests.ps1' } | 
             ForEach-Object { Write-Verbose $_.name; . $_.FullName } 
                  } 
 } 