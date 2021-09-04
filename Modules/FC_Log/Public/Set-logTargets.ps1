function Set-logTargets{
<#
    .Synopsis
       Turns on or off the targets for the FC_log module. This controls where Write-Log logs the messages.
	.Description
        This function only needs to be called once at the start of the script. You can set some or all of the options by only passing the parameters that correspond to the formatting option you want to enable.
	.PARAMETER Console
        Default: -1
        Position: 0

		When set to 1, Write-Log will Send the log to the Information/Debug/Verbose/Warning/Error streams. By default, this is on. 
        When set to 0, it will explicitly turn off that target
	.PARAMETER WindowsEventLog
        Default: -1
        Position: 1
		
        When set to 1, Write-Log will Send the log to the windows event log. It will use the $script:LogSource value as set in FC_Log.psm1
        When set to 0, it will explicitly turn off that target
	.PARAMETER File
        Default: null
        Position:  2

		When set to a valid path, Write-Log will send the log to the specified file
	.PARAMETER Speech
        Default: -1
        Position:  3

		When set to 1, Write-Log will use microsoft's speech synthesis to speek the message to you. 
        When set to 0, it will explicitly turn off that target


    #>
    param([Parameter(Position=0)][int] $Console = -1,
    [Parameter(Position=1)][int] $WindowsEventLog = -1,
    [Parameter(Position=2)][string[]] $File = "-",
    [Parameter(Position=3)][int] $Speech = -1)

	if( $PSVersionTable.PSEdition -eq 'core' -and $Speech -eq 1 ){
		Write-Error "I cannot log to the Speech on pwsh core" -ErrorAction Stop
	}
	if( $PSVersionTable.PSEdition -eq 'core' -and $WindowsEventLog -eq 1 ){
		Write-Error "I cannot log to the Windows Event Log on pwsh core without some workarounds. See https://github.com/brandonmcclure/friendly-chainsaw/issues/61"
	}
    if ($Console -eq 1 -or $Console -eq 0){
        $script:logTargets['Console'] = $Console
    }
    if ($WindowsEventLog -eq 1 -or $WindowsEventLog -eq 0){
        $script:logTargets['WindowsEventLog'] = $WindowsEventLog
    }
    if ($File -eq "-"){
    }
    elseif (![string]::IsNullOrEmpty($File)){
        foreach($File2 in $File){
            if ($file2 -notin $script:logTargetFileNames){
                $fileParentDir = Split-Path $file2 -Parent
                if (-not (Test-Path $fileParentDir)){
                    try{
                        New-Item -Path $fileParentDir -ItemType Directory -Force
                    }
                    catch{
                        throw "Could not set log target to: $fileParentDir. Path does not exist"
                    }
                }
                $script:logTargetFileNames += $File2
            }
        }
        $script:logTargets['File'] = 1
    }
    else{
        $script:logTargets['File'] = 0
    }
    if ($Speech -eq 1 -or $Speech -eq 0){
        $script:logTargets['Speech'] = $Speech
    }
}