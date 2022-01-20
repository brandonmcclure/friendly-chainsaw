function Get-FCSecret{
    param($Name,[int]$ClipboardTime = 10)

    Get-Secret -Name $Name -AsPlainText | set-Clipboard; foreach($i in 1..$ClipboardTime){write-Host $(""*$i);sleep 1} set-Clipboard "garbage";
}