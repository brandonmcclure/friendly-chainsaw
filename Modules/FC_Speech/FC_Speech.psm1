Add-Type -AssemblyName System.speech

if (!$global:SpeechModuleListener) {
    ## For XP's sake, don't create them twice...
    $global:SpeechModuleSpeaker = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $global:SpeechModuleListener = New-Object System.Speech.Recognition.SpeechRecognizer
}
$script:SpeechModuleMacros = @{}
## Add a way to turn it off
$script:SpeechModuleMacros.Add("Stop Listening", {$script:listen = $false; Suspend-Listening})
$script:SpeechModuleMacros.Add("Run Notepad", {"C:\Program Files (x86)\Notepad++\notepad++.exe"})
$script:SpeechModuleComputerName = ${env:ComputerName}


Set-Alias asc Add-SpeechCommands
Set-Alias rsc Remove-SpeechCommands
Set-Alias csc Clear-SpeechCommands
Set-Alias say Out-Speech
Set-Alias listen Start-Listener

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