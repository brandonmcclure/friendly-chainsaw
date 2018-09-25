$script:logLevelOptions = @{"Debug" = 0;"Verbose" = 5; "Info" = 10; "Warning" = 20; "Error" = 30; "Disable" = 100} 
$script:LogSource = "FC Powershell Scripts"
$script:logTargetFileDir = "logs\$($env:computername)\$(Get-Date -f yyyy-MM-dd)\"
$script:logTargetFileName = $null
$script:logLevel = 10
$script:logTargetConsole = 1
$script:logTargetFile = 0
$script:logTargetWinEvent = 0

$script:logFormattingOptions = @{"PrefixCallingFunction" = 0; "AutoTabCallsFromFunctions" = 0; "PrefixTimestamp" = 0} 
$script:logTargets = @{"Console" = 1; "WindowsEventLog" = 0; "File" =0; "Speech" = 1}
Write-Verbose "Importing Functions" 
 
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