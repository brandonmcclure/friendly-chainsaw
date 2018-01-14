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
	[ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
    [switch] $winEventLog
    , [switch] $ssl = $false
    ,[string] $domain = 'ipcop.org'
    , [string] $baseURL = '/2.0.0/en/install/html/'
    ,[string] $outputDirectory = 'E:\Collect It\web crawler\ipcop\install'
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

if ($ssl){ $header = 'https'}else{$header ='http'}

$robotsURL = "$($header)://www.$domain/robots.txt"
$robotExclusions = @()
try{
    $response = Invoke-WebRequest -Uri $robotsURL -OutFile "$outputDirectory\robots.txt"
    #TODO: Parse robots.txt and add to $robotExclusions
    Write-Log "I should code for handling this robots.txt that you can read here: $outputDirectory\robots.txt" Warning
}
catch{
    Write-Log "Could not find robots.txt"
}

$url = "$($header)://www.$domain$baseURL"
$outFilePath = "$outputDirectory\test.html"
#TODO: Persist a dictionary of the local resource and it's last update time to reduce redeundant requests. 
Write-Log "requesting from $url" Debug


$responseTimer = [system.diagnostics.stopwatch]::startNew()
$response = Invoke-WebRequest -Uri $url -OutFile $outFilePath -PassThru
$responseTimer.Stop()
$responseTime = $responseTimer.ElapsedMilliseconds
Write-Log "web response took $responseTime milliseconds" Debug

#TODO: Use the responseTime to alter the $requestTimeout up or down

if ($logLevel -eq "Debug"){
    $response
}

foreach ($link in $response.Links){
 #   $link
}