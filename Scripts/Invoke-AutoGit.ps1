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
	[string] $gitRemote = $null
	)
#region Basic script init
	Import-Module FC_Log, FC_Core -ErrorAction Stop

	Set-LogLevel $logLevel
	Get-Location | Push-Location
#endregion
try{
	Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug

    Set-Location $path
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

    if ([string]::IsNullOrEmpty($gitRemote)){
	    Write-Log "Bypassing git push due to null gitRemote value" Debug
    }
    else{
	    & git push origin master
    }

    Pop-Location | Set-Location
    Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug
}

