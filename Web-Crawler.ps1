<#
    .Synopsis
       Starting script for friendly-chainsaw framework
	.Description
		TODO: add this
    .LINKS
        TODO: And add links to documentation for your script
    .PARAMETER
        logLevel

    #>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info",
    [switch] $winEventLog
    , [switch] $ssl = $false
    ,[string] $domain = 'ipcop.org'
    , [string] $baseURL = '/2.0.0/en/install/html/'
    ,[string] $outputDirectory = 'E:\Collect It\web crawler\ipcop\install\'
    ,[int] $CacheDays = -1
    , [int] $threadCount = 10
    )

if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel 
Set-logTargetWinEvent $winEventLog

$requestTimeoutBase = 1
$requestTimeout = $requestTimeoutBase

if (!(test-PAth $outputDirectory)){
    mkdir $outputDirectory
}

function Invoke-WebRequest_FC{
param([string]$Uri =$null
,[string] $OutFile = $null
,[switch] $PassThru = $false
,[switch] $crawl = $false)

$linkFile = "$($OutFile)_Links.clxml"
Write-Log "Requesting page: $Uri"
if (!(Test-Path  $OutFile)){
    Write-Log "Data is not cached, sending new request to $Uri." Debug
    Write-Log  "Response will be written to: $OutFile" Debug
    if ($PassThru){
        $responseTimer = [system.diagnostics.stopwatch]::startNew()
        $results = Invoke-WebRequest -Uri $Uri -OutFile $OutFile -PassThru
        $responseTimer.Stop()
        $responseTime = $responseTimer.ElapsedMilliseconds
        Write-Log "web response took $responseTime milliseconds" Debug
        $links = $results.Links | Select href -ExpandProperty href
        Export-Clixml -InputObject $links -Path $linkFile

        $results = Get-Content $OutFile
    }
    else{
        $responseTimer = [system.diagnostics.stopwatch]::startNew()
        $results = Invoke-WebRequest -Uri $Uri -OutFile $OutFile -PassThru
        $responseTimer.Stop()
        $responseTime = $responseTimer.ElapsedMilliseconds
        Write-Log "web response took $responseTime milliseconds" Debug
        $links = $results.Links | Select href -ExpandProperty href
        Export-Clixml -InputObject $links -Path $linkFile
        $results = $null
    }
    $obj = New-Object -TypeName psobject
    $obj | Add-Member -type NoteProperty -Name 'index' -Value $index
    $obj | Add-Member -Type NoteProperty -Name 'ElapsedTime' -Value $responseTimer.ElapsedMilliseconds
    $responseTimes += $obj
}
elseif( $(Get-ChildItem $OutFile).LastWriteTime -le (Get-Date).AddDays($cacheDays)){
    Write-Log "Refreashing local cache. File path: $OutFile" Debug
    Remove-item $OutFile | Out-Null
    Remove-Item $linkFile -ErrorAction Ignore | Out-Null
    if ($PassThru){
        $responseTimer = [system.diagnostics.stopwatch]::startNew()
        $results = Invoke-WebRequest -Uri $Uri -OutFile $OutFile -PassThru
        $responseTimer.Stop()
        $responseTime = $responseTimer.ElapsedMilliseconds
        Write-Log "web response took $responseTime milliseconds" Debug

        $links = $results.Links | Select href -ExpandProperty href
        Export-Clixml -InputObject $links -Path $linkFile
        $results = Get-Content $OutFile
    }
    else{
        $responseTimer = [system.diagnostics.stopwatch]::startNew()
        $results = Invoke-WebRequest -Uri $Uri -OutFile $OutFile -PassThru
        $responseTimer.Stop()
        $responseTime = $responseTimer.ElapsedMilliseconds
        Write-Log "web response took $responseTime milliseconds" Debug
        $links = $results.Links | Select href -ExpandProperty href
        Export-Clixml -InputObject $links -Path $linkFile
        $results = $null
    }
    $obj = New-Object -TypeName psobject
    $obj | Add-Member -type NoteProperty -Name 'index' -Value $index
    $obj | Add-Member -Type NoteProperty -Name 'ElapsedTime' -Value $responseTime
    $responseTimes += $obj
}
else{
    Write-Log "Locally cached result last updated at $($(Get-ChildItem $OutFile).LastWriteTime)"  
    $links = Import-Clixml -Path $linkFile
    $results = Get-Content $OutFile

}

$Script:responseTimes = $Script:responseTimes | Where {$_.index -lt (Measure-Object -InputObject $Script:responseTimes -Maximum)-20}

if ($crawl){
	$index = 0
    while( $index -lt $links.Count){
        $currLink = $links[$index]
        
        $url = "$uri/$currLink"
        Write-Log "Checking out link $currLink AT $url"
        $outFilePath = "$outputDirectory$currLink"
        if ($currLink -in $Script:gatheredLinks){
            Write-Log "Already reviewed"
        }
        elseif($currLink -in $robotExclusions){
            Write-Log "Skipping $currLink due to robots.txt" Warning
        }
        elseif($currLink.Substring(0,4) -eq 'http'){
            Write-Log "Current link outside of scope" Warning
        }
        else{
            $Script:gatheredLinks += $currLink
            $responseTimer = [system.diagnostics.stopwatch]::startNew()
            $incResponse = Invoke-WebRequest_FC -Uri $url -OutFile $OutFile -crawl
            
            $responseTimer.Stop()
            $incLinks = Import-Clixml "$($outFilePath)_Links.clxml"
            

        }
        $links.Remove($currLink)
        

        $index++


        
        if ($requestTimeoutActiveValue-lt $requestTimeoutBase){
            $requestTimeoutActiveValue = $requestTimeoutBase
        }
        sleep $requestTimeoutActiveValue

    }
}

Write-Output $results
}
function Invoke-WebCrawl{
param($url,$outFilePath,$outputDirectory,$robotExclusions)
    $response = Invoke-WebRequest_FC -Uri $url -OutFile $outFilePath -PassThru
    $currLinks = Import-Clixml "$($outFilePath)_Links.clxml"

    $index = 0
    while( $index -lt $currLinks.Count){
        $currLink = $currLinks[$index]
        Write-Log "Checking out link $currLink"
        $url = "$($header)://www.$domain$baseURL$currLink"
        $outFilePath = "$outputDirectory$currLink"
        if ($currLink -in $Script:gatheredLinks){
            Write-Log "Already reviewed"
        }
        elseif($currLink -in $robotExclusions){
            Write-Log "Skipping $currLink due to robots.txt" Warning
        }
        elseif($currLink.Substring(0,4) -eq 'http'){
            Write-Log "Current link outside of scope" Warning
        }
        else{
            $Script:gatheredLinks += $currLink
            $responseTimer = [system.diagnostics.stopwatch]::startNew()
            $incResponse = Invoke-WebRequest_FC -Uri $url -OutFile $outFilePath -PassThru
            
            $responseTimer.Stop()
            $incLinks = Import-Clixml "$($outFilePath)_Links.clxml"
            

        }
        $currLinks.Remove($currLink)
        

        $index++


        
        if ($requestTimeoutActiveValue-lt $requestTimeoutBase){
            $requestTimeoutActiveValue = $requestTimeoutBase
        }
        sleep $requestTimeoutActiveValue

    }
}

if ($ssl){ $header = 'https'}else{$header ='http'}

$Script:gatheredLinks = @() 
$Script:responseTimes = @()
$robotsURL = "$($header)://www.$domain/robots.txt"
$robotExclusions = @()
try{
    
    $outFilePath = "$outputDirectory\robots.txt"
    $response = Invoke-WebRequest_FC -Uri $robotsURL -OutFile $outFilePath -PassThru
    #TODO: Parse robots.txt and add to $robotExclusions
    foreach ($line in $response){
        Write-Log "$line" Debug
        if ($line.Substring(0,$line.IndexOf(':')) -eq 'Disallow'){
            $robotExclusions += $line.Substring($line.IndexOf('/')+1,$line.Length - $line.IndexOf('/')-1 )
        }
    }
    Write-Log "Parsed out $($robotExclusions.Count) exclusion rules"
}
catch{

    #This catch is designed to catch errors with the execution of the sql files, and package them into an array of objects so that we can itterate through all of the failed files together at the end of the script
    $caughtExecption = $_
    Write-Log "Error at $($caughtExecption.InvocationInfo.ScriptLineNumber), message: $($caughtExecption.Exception.Message)"
    Write-Log "Could not find robots.txt"
}
$url = "$($header)://www.$domain$baseURL"

$curName = 'index'
$outFilePath = "$outputDirectory$curName.html"
#TODO: Persist a dictionary of the local resource and it's last update time to reduce redeundant requests. 
Write-Log "requesting from $url" Debug

Invoke-WebRequest_FC -Uri $url -outFile $outFilePath -crawl

$x = 0;
#TODO: Use the responseTime to alter the $requestTimeout up or down
