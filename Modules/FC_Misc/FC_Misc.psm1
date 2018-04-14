Function Invoke-BlenderRender{
<#
    .Synopsis
       Starts rendering a blender .blend animation or image.
    .LINKS
        Belnder command line https://docs.blender.org/manual/en/dev/render/workflows/command_line.html

    #>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info",
    [switch] $winEventLog
    ,[string] $blenderEXEPath = "E:\Games\SteamLibrary\steamapps\common\Blender\Blender.exe"
    ,[string] $BlendFileToRender = $null
    ,[string] $outputDir = "E:\Collect It\Blender"
    ,[string] $option = $null #Set to -a to render the whole animation
    , [int] $threadCount = $null
    )

if ([string]::IsNullOrEmpty($logLevel)){$log:Level = "Info"}
Set-LogLevel $logLevel 
Set-logTargetWinEvent $winEventLog

if ([string]::IsNullOrEmpty($BlendFileToRender)){
    Write-Log "You need to pass a value to the BlendFileToRender parameter" Error -ErrorAction Stop
}

if (!(Test-Path $BlendFileToRender)){
    Write-Log "Could not find $BlendFileToRender. Aborting" Error -ErrorAction Stop
}

if (!(Test-Path $outputDir)){
    Write-Log "Output directory does not exist. $outputDir" Error -ErrorAction Stop
}

if ($threadCount -eq $null -or $threadCount -le 0){
    $threadCount = 0
}
$inputFileName = Split-Path $BlendFileToRender -Leaf

$inputFileName = $inputFileName.Substring(0,$inputFileName.IndexOf("."))
$timeStamp = (Get-Date).ToString("yyyyMMdd_hhmmss")

$outputPath = "$outputDir\$($inputFileName)_$($timeStamp)_"

if ([string]::IsNullOrEmpty($option)){
    Write-Log "Calling $blenderEXEPath -b $blendFileToRender -o $outputPath $option -t $threadCount $option" Debug
    & $blenderEXEPath -b $blendFileToRender -o "$outputPath" -t $threadCount
}
else{
    Write-Log "Calling: $blenderEXEPath -b $blendFileToRender -o $outputPath $option -t $threadCount " Debug
    & $blenderEXEPath -b $blendFileToRender -o "$outputPath" $option -t $threadCount
}

[console]::beep(500,300)
}Export-Modulemember -Function Invoke-BlenderRender