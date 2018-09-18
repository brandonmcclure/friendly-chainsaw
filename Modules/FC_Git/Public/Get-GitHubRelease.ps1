Function Get-GitHubRelease{
<#
Write-Log "Current location: $(Get-Location)" Debug
    .Synopsis
      My attempt at a generic release downloader from GitHub. Specifically this was written to download the pandoc releases
    .PARAMETER fileFormat
        Right now this function is only able to download release files with a name like <*><versionNumber><*>.<*>

        ie. Pandoc's release files will look like: Pandoc-2.0.5-windows.msi

        To get this file, the format I would pass in is pandoc-0-windows.msi. 

        the 0 is a place holder for the actual version that will be downloaded. 
    .PARAMETER repo
        The user name and repository seperated by a forward slash. 

        IE for pandoc, this would be: "jgm/pandoc" 
    .LINK
       I followed this gist to write this script - https://gist.github.com/MarkTiedemann/c0adc1701f3f5c215fc2c2d5b1d5efd3#file-download-latest-release-ps1-L9
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Warning"
,[switch] $winEventLog
,[string] $repo = $null
,[string] $fileFormat = $null
,[string] $tag
,[switch] $forceDownload
,[switch] $cleanupLocalFiles)

$currentLogLevel = Get-LogLevel
if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog

try{    
    $releases = "https://api.github.com/repos/$repo/releases" 
 
    if ([String]::IsNullOrEmpty($tag)){
        Write-Log "No tag specified, determining latest release for the $repo repository"
        $tag = (Invoke-WebRequest $releases -ErrorAction Stop | ConvertFrom-Json)[0].tag_name 
    }
 
    $name1 = $fileFormat.Split("0")[0] 
    $name2 = $fileFormat.Split("0")[1].Split(".")[0] 
    $ext = $fileFormat.Split("0")[1].Split(".")[1] 
    $zip = "$name1$tag$name2.$ext" 
    $dir = "$name1$tag$name2" 

    $download = "https://github.com/$repo/releases/download/$tag/$zip" 
    Write-Log "Will download the file: $download" Debug
    
    $localDownloadDir = "$env:TEMP\$dir"
    Write-Log "Into $localDownloadDir" Debug
    if (!(Test-Path $localDownloadDir)){
        Write-Log "Creating the directory to hold the release file"
        Mkdir $localDownloadDir
    }
    if (!(Test-Path "$localDownloadDir\$zip") -or $forceDownload){
        Write-Log "Dowloading the release taged as $tag"
        Invoke-WebRequest $download -Out "$localDownloadDir\$zip"
    }
    else{
        Write-Log "file already exists on your PC. Skipping download."
    }
}
catch{
    if ((Test-Path $localDownloadDir) -and $cleanupLocalFiles){
        rm $localDownloadDir
    }
    Set-LogLevel $currentLogLevel
}

if ((Test-Path $localDownloadDir) -and $cleanupLocalFiles){
    rm $localDownloadDir
}
Set-LogLevel $currentLogLevel

Write-Output "$localDownloadDir\$zip"

} Export-ModuleMember -Function Get-GitHubRelease