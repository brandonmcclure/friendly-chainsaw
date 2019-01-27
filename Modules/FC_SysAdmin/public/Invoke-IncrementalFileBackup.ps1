function Invoke-IncrementalFileBackup {
<#
   
#>

Param(
[ValidateSet("Debug","Verbose","Info","Warning","Error", "Disable")][string] $logLevel = "Debug",
  [Parameter(position=0,ValueFromPipelineByPropertyName)][string]$SourceDirectory = $null,
  [Parameter(position=1,ValueFromPipelineByPropertyName)][string]$BackupToRootPath = $null
  ,[Parameter(position=2,ValueFromPipelineByPropertyName)][string] $BackupName = $null
  ,[Parameter(position=3,ValueFromPipelineByPropertyName)][string] $BackupInstanceFormat = $null
  ,[Parameter(position=4,ValueFromPipelineByPropertyName)][string[]] $ExcludeDirectories = $null
  ,[Parameter(position=5,ValueFromPipelineByPropertyName)][int] $NumberOfIncrementalBeforeFull = 10
  ,[switch]$ForceFull = $true
)
$OrigLogLevel = Get-LogLevel
$originalLocation = Get-Location
Write-Log "Original log level: $OrigLogLevel" Debug
try{
    if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
    Set-LogLevel $logLevel

    if([string]::IsNullOrEmpty($SourceDirectory)){
        Write-Log "Please pass a valid path to the directory you want to backup using the -SourceDirectory parameter" Error -ErrorAction Stop
    }
    if([string]::IsNullOrEmpty($BackupToRootPath)){
        Write-Log "Please pass a valid path to the root directory the backup will be written to using the -BackupToRootPath parameter" Error -ErrorAction Stop
    }
    if([string]::IsNullOrEmpty($BackupName)){
        Write-Log "Please pass a name for the backup, which will be used to create the sub folder structure of the timestamped backup files using the -BackupName parameter" Error -ErrorAction Stop
    }

    $anchorBackupDirectory = "$BackupToRootPath\$BackupName"

    Write-Log "Loading previous backup data" Verbose
    $prevBackupDir = Get-ChildItem $anchorBackupDirectory | Where {$_.PSIsContainer }| sort name -Descending | select -First 1 -ExpandProperty FullName
    $PreviousBackupPath = "$prevBackupDir\FC_BackupData.json"
    $PreviousBackup = Get-Content $PreviousBackupPath -Raw | ConvertFrom-Json -ErrorAction Stop
    Write-Log "Done loading previous backup data" Verbose

    $backupInstant = $(Get-Date -Format $BackupInstanceFormat)
    if(!$ForceFull -or $PreviousBackup.backupType -eq "Full"){
        $backupType = "Incremental"
    }
    elseif($ForceFull -or ($PreviousBackup.backupType -eq "Incremental" -and $PreviousBackup.IndexSinceLastFull -gt $NumberOfIncrementalBeforeFull)){
        $backupType = "Full"
    }
    
    Write-Log "Backup type: $backupType"
    $BackupInstanceName = "$($backupInstant)_$backupType"
    $destination = "$anchorBackupDirectory\$BackupInstanceName"

    If(Test-path $SourceDirectory){
        if(Test-Path $BackupToRootPath){
        
        }
        else{
            Write-Error "Could not find the path to the backup directory: $BackupToRootPath"
        }
    }
    else{
    Write-Error "Can not find path: $SourceDirectory"
    }
    
    $outBackupDataPath = "$destination\FC_BackupData.json"
    
    [string] $backupDataConnectionString = $outBackupDataPath

    if(!(Test-Path $destination)){
        New-Item $destination -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    Write-Log "File backup started."
   
    Write-Log "root destination directory: $destination" -tabLevel 1 

    Write-Log "Scanning files ..."

    Set-Location $SourceDirectory
    $hashAlgorithm = "SHA256"
    $FileIOToCopy = Get-ChildItem $SourceDirectory -force -recurse #| where { ![string]::IsNullOrEmpty($ExcludeDirectories) -and $_.FullName -notmatch $ExcludeDirectories}
    $FilesToCopy = $FileIOToCopy | where {$_.PSIsContainer -ne $true} | Select Name,FullName,Length
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "FileHash" -Value ""
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "FileHashAlgo" -Value $hashAlgorithm
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "WasUpdated" -Value 0
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "LastBackup" -Value "$backupInstant"
    $fileCount = $FilesToCopy | Measure-Object | select -ExpandProperty Count
    $fileCountIndex = 0

    
        foreach($file in $FilesToCopy){
            
             $file.FileHash = Get-FileHash -Path $file.FullName -Algorithm $hashAlgorithm | select -ExpandProperty Hash
            $relativePath = "$(Resolve-Path -Relative (Split-Path $file.FullName -Parent))\$($file.Name)"
            $relativePath = $relativePath.Substring(2,$relativePath.Length-2)
             Write-Progress -Activity "Copying files" -status "$relativePath" -percentComplete ($fileCountIndex / $fileCount*100)
             $fileCountIndex++
            $destinationFilePath = "$destination$relativePath"
            $DestinationFIleParentDirPath = Split-Path $destinationFilePath -Parent
            if ($backupType -eq "Full"){
                if (!(Test-Path (Split-Path $destinationFilePath -Parent))){
                        New-Item (Split-Path $destinationFilePath -Parent) -ItemType Directory -Force -ErrorAction Continue | out-Null
                    }
                    
                     Copy-Item -Path $file.FullName -Destination $destinationFilePath -Force
    }
    elseif($backupType -eq "Incremental"){

                Write-Log (($file | select FullName,LastBackup,WasUpdated) -join ",") Verbose

            
            
               

                if($file.FileHash -eq ($PreviousBackup.Files | where {$_.Files.Name -eq $file.Name} | select -ExpandProperty FileHash)){
                    continue;
                }
            }
         }
        $outputObj = New-Object -TypeName psobject
        $outputObj | Add-Member -MemberType NoteProperty -Name "BackupInstance" -Value $backupInstant
        $outputObj | Add-Member -MemberType NoteProperty -Name "backupType" -Value $backupType
        $outputObj | Add-Member -MemberType NoteProperty -Name "PreviousBackup" -Value $PreviousBackupPath
        $outputObj | Add-Member -MemberType NoteProperty  -Name "Files" -Value $FilesToCopy

        $outputObj | ConvertTo-Json -Depth 5 | Set-Content $outBackupDataPath

        Write-Log "Performing metadata file cleaning"
        $TotalbackupCount = (Get-Content "$anchorBackupDirectory\FC_RootBackup.log" | Measure-Object).Count
        "$BackupInstanceName,$TotalbackupCount" | Add-Content "$anchorBackupDirectory\FC_RootBackup.log"
        $clearLastNBackups = 10
        $numberOfBackupsToDelete = $TotalbackupCount - $clearLastNBackups

        if ($numberOfBackupsToDelete -gt 0){
            Write-Log "Removing the last $numberOfBackupsToDelete from $anchorBackupDirectory\FC_RootBackup.log" Debug
            (Get-Content "$anchorBackupDirectory\FC_RootBackup.log" | Select-Object -Skip $numberOfBackupsToDelete) | Set-Content "$anchorBackupDirectory\FC_RootBackup.log"
        }
        Write-Log "Done cleaning up the metadata file"
        Write-Log "File backup completed."
        
    }
catch{
    throw
}
finally{
Set-Location $originalLocation
}
}export-modulemember -function Invoke-IncrementalFileBackup
