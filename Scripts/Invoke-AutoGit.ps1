<#
    .Synopsis
      Will add and commit changes to all files in a git repo every X seconds, and then push the commits to a remote after the script is terminated. 
    .PARAMETER path
        The path to a valid git repo, or a directory that you want to create a repo in. Changes to files in this directoy will be added to this repo
    .PARAMETER loopDelay
        The number of seconds that the script will wait before checking for modified files and commiting them
    .PARAMETER filterMask
        A string to only include files that match the pattern. If not specified, all files will be added/commited
    .PARAMETER gitRemote
        If specified, and the $path is not an existing repository, we will clone from this repository. It will also push to the origin if this is populated
    #>
[CmdletBinding(SupportsShouldProcess=$true)]  
param(
	[string] $path = $null,
	[ValidateNotNullOrEmpty()][string] $logLevel = "Info",
	[int] $loopDelay = 5,
	[string] $filterMask = $null,
	[string] $gitRemote = $null,
[switch] $winEventLog
	)
#region Basic script init
	Import-Module FC_Log, FC_Core, FC_Data -DisableNameChecking -Force -ErrorAction Stop

	if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog
    $origLocation = Get-Location
#endregion
Write-Log "Testing the event log"
Start-Job -ScriptBlock{
param([string] $path,	[int] $loopDelay,	[string] $filterMask,	[string] $gitRemote,[switch] $winEventLog	)

    	Import-Module FC_Log, FC_Core, FC_Data -DisableNameChecking -Force -ErrorAction Stop

	if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
Set-LogLevel $logLevel
Set-logTargetWinEvent $winEventLog
try{
    if (!(Test-Path $path)){
        mkdir $path | Out-Null
    }
    Set-Location $path -ErrorAction Stop
    
	Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug

    #Clone a git repo if $path is not a valid git repo
    if (!(Test-Path "$($path)\.git")){
	    if ([string]::IsNullOrEmpty($gitRemote)){
		    Write-Log "$path is not a valid repo. Initing new git repo. Please ensure you have setup the Git Config"
		    & git init
	    }
	    else{
		    Write-Log "$path is not a valid repo. Creating git repo. Please ensure you have setup the Git Config"
	        & git clone "$gitRemote" .
	    }
	
	    $files = Get-ChildItem $path -Filter $filterMask | Select Fullname

	    foreach ($file in $files){
		    & git add $file.FullName
	    }
	    & git commit -m "[$([DateTime]::Now)] - Auto Initial Commit"
    }

    if (!(Test-Path "$($path)\.git")){
        Write-Log "Error creating or cloning the repo into $path." Error -ErrorAction Stop
    }
    #Main loop
    Write-Log "Starting the endless loop"
    while (1 -eq 1){
        $indexFiles = @()
        if ([string]::IsNullOrEmpty($filterMask)){
            $indexFiles += & git ls-files --others --exclude-standard
            $indexFiles += & git diff --name-only
        }
        $indexFiles += & git ls-files --others --exclude-standard | Where {$_ -like $filterMask}
        $indexFiles += & git diff --name-only | Where {$_ -like $filterMask}
	    Write-Log "modified files Count: $($indexFiles.Count)" Debug
	    if ($indexFiles.Count -gt 0){
		    foreach ($file in $indexFiles){
			    & git add $file
		    }

            & git commit -m "[$([DateTime]::Now)] - Auto Modification Commit"
		
	    }
	
		sleep $loopDelay
    }
}
finally{
    Write-Log "Loop has ended."
    Write-Log "Current location: $(Get-Location), origLocation: $origLocation" Warning

    if ([string]::IsNullOrEmpty($gitRemote)){
	    Write-Log "Bypassing git push due to null gitRemote value" Debug
    }
    else{
        Write-Log "Pushing to remote, hopefully it works" Debug
        #I can't use a standard run invocation using & like I do elsewhere because the output is in stderr and causes the finally block to choke. 
        # By using Start-MyProcess I can call git, and then return both stderr and stdout in a PSObject to be inspected later. Currently I just assume it was succesfull, but ideally there would be some error checking here. 
        $result = Start-MyProcess -EXEPath git -options "push origin master" 
    }
    
    Set-Location $origLocation
    Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
}
} -ArgumentList ($path,$loopDelay,$filterMask,$gitRemote,$winEventLog) -Name "$(Get-JobPrefix)AutoGit"
sleep 5


Get-MyJobs | Remove-Job -Force
