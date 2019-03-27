function Invoke-IncrementalFileBackup {
  <#
   
#>

  param(
    [ValidateSet("Debug","Verbose","Info","Warning","Error","Disable")] [string]$logLevel = "Debug",
    [Parameter(position = 0,ValueFromPipelineByPropertyName)] [string]$SourceDirectory = $null,
    [Parameter(position = 1,ValueFromPipelineByPropertyName)] [string]$BackupToRootPath = $null
    ,[Parameter(position = 2,ValueFromPipelineByPropertyName)] [string]$BackupName = $null
    ,[Parameter(position = 3,ValueFromPipelineByPropertyName)] [string]$BackupInstanceFormat = $null
    ,[Parameter(position = 4,ValueFromPipelineByPropertyName)] [string[]]$ExcludeDirectories = $null
    ,[Parameter(position = 5,ValueFromPipelineByPropertyName)] [int]$NumberOfIncrementalBeforeFull = 10
    ,[switch]$ForceFull
    ,[int]$NumberOfBackupsToKeep = 20
    ,[switch] $compressFiles = $true
  )

  

function Split-Array ([object[]]$InputObject,[int]$SplitSize=100)
{
#https://powershell.org/forums/topic/splitting-an-array-in-smaller-arrays/
$length=$InputObject.Length
for ($Index = 0; $Index -lt $length; $Index += $SplitSize)
{
#, encapsulates result in array
#-1 because we index the array from 0
,($InputObject[$index..($index+$splitSize-1)])
}
}

  $OrigLogLevel = Get-LogLevel
  $originalLocation = Get-Location

  import-module FC_Data -force -DisableNameChecking
  Write-Log "Original log level: $OrigLogLevel" Debug
  try {
    if ([string]::IsNullOrEmpty($logLevel)) { $logLevel = "Info" }
    Set-LogLevel $logLevel

    if ([string]::IsNullOrEmpty($SourceDirectory)) {
      Write-Log "Please pass a valid path to the directory you want to backup using the -SourceDirectory parameter" Error -ErrorAction Stop
    }
    if ([string]::IsNullOrEmpty($BackupToRootPath)) {
      Write-Log "Please pass a valid path to the root directory the backup will be written to using the -BackupToRootPath parameter" Error -ErrorAction Stop
    }
    if ([string]::IsNullOrEmpty($BackupName)) {
      Write-Log "Please pass a name for the backup, which will be used to create the sub folder structure of the timestamped backup files using the -BackupName parameter" Error -ErrorAction Stop
    }

    $anchorBackupDirectory = "$BackupToRootPath\$BackupName"

    
    $prevBackupDir = Get-ChildItem $anchorBackupDirectory | Where-Object { $_.PSIsContainer } | sort name -Descending | Select-Object -First 1 -ExpandProperty FullName
    if([string]::IsNullOrEmpty($prevBackupDir)){
        
    }
    else{
        Write-Log "Loading previous backup data" Verbose
        $PreviousBackupPath = "$prevBackupDir\FC_BackupData.json"
        $PreviousBackup = Get-Content $PreviousBackupPath -Raw | ConvertFrom-Json -ErrorAction Stop
        $IndexSinceLastFull = $PreviousBackup.IndexSinceLastFull
        Write-Log "Done loading previous backup data" Verbose
    }
    

    $backupInstant = $(Get-Date -Format $BackupInstanceFormat)
    if ($ForceFull -or $PreviousBackup -eq $null -or ($PreviousBackup.backupType -eq "Incremental" -and $PreviousBackup.IndexSinceLastFull -gt $NumberOfIncrementalBeforeFull)) {
      $backupType = "Full"
      $IndexSinceLastFull = 0
    } 
    
    else {
      $backupType = "Incremental"
    }

    Write-Log "Backup type: $backupType"
    $BackupInstanceName = "$($backupInstant)_$backupType"
    $destination = "$anchorBackupDirectory\$BackupInstanceName"

    if (Test-Path $SourceDirectory) {
      if (Test-Path $BackupToRootPath) {

      }
      else {
        Write-Error "Could not find the path to the backup directory: $BackupToRootPath"
      }
    }
    else {
      Write-Error "Can not find path: $SourceDirectory"
    }

    $outBackupDataPath = "$destination\FC_BackupData.json"

    [string]$backupDataConnectionString = $outBackupDataPath

    if (!(Test-Path $destination)) {
      New-Item $destination -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    Write-Log "File backup started."

    Write-Log "root destination directory: $destination" -tabLevel 1

    Write-Log "Scanning files ..."

    Set-Location $SourceDirectory
    $hashAlgorithm = "SHA256"
    $FileIOToCopy = Get-ChildItem $SourceDirectory -Force -Recurse #| where { ![string]::IsNullOrEmpty($ExcludeDirectories) -and $_.FullName -notmatch $ExcludeDirectories}
    $FilesToCopy = $FileIOToCopy | Where-Object { $_.PSIsContainer -ne $true } | Select-Object Name,FullName,Length
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "FileHash" -Value ""
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "FileHashAlgo" -Value $hashAlgorithm
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "WasUpdated" -Value 0
    $FilesToCopy | Add-Member -MemberType NoteProperty -Name "LastBackup" -Value "$backupInstant"
    $fileCount = $FilesToCopy | Measure-Object | Select-Object -ExpandProperty Count
    $fileCountIndex = 0

    $parallelQueues = 5


    $splitArrays = @()

    $splitArrays = Split-Array -InputObject $FilesToCopy -SplitSize ($fileCount/5)
    $jobs = @()
    $i = 0;
        foreach ($array in $splitArrays){
        $i++
            $jobName = "$(Get-JobPrefix)FileBackup$i"
            $jobs += Start-Job  {
                param($files,$hashAlgorithm,$destination,$PreviousBackup)
                foreach ($file in $files) {

      $file.FileHash = Get-FileHash -Path $file.FullName -Algorithm $hashAlgorithm | Select-Object -ExpandProperty Hash
      $relativePath = "$(Resolve-Path -Relative (Split-Path $file.FullName -Parent))\$($file.Name)"
      $relativePath = $relativePath.Substring(2,$relativePath.Length - 2)
      $destinationFilePath = "$destination\$relativePath"
      $DestinationFIleParentDirPath = Split-Path $destinationFilePath -Parent
      Write-Log (($file | Select-Object FullName,LastBackup,WasUpdated) -join ",") Verbose
       if (!(Test-Path (Split-Path $destinationFilePath -Parent))) {
          New-Item (Split-Path $destinationFilePath -Parent) -ItemType Directory -Force -ErrorAction Continue | Out-Null
        }

      if ($backupType -eq "Full") {
        Copy-Item -Path $file.FullName -Destination $destinationFilePath -Force
        $file.WasUpdated = 1
      }
      elseif ($backupType -eq "Incremental") {

        if ($file.FileHash -eq ($PreviousBackup.Files | Where-Object { $_.FullName -eq $file.FullName } | Select-Object -ExpandProperty FileHash)) {
            $prevFilePath = "$prevBackupDir\$relativePath"
            if(!(Test-Path $prevFilePath)){
                continue;
            }
            try{
            New-Item -Path $destinationFilePath -ItemType SymbolicLink -Value $prevFilePath -ErrorAction Stop | Out-Null
            }
            catch{
                $x = 0;
            }
        }
        else {
           
          Copy-Item -Path $file.FullName -Destination $destinationFilePath -Force
          $file.WasUpdated = 1
        }
      }
    }
            }-ArgumentList ($array,$hashAlgorithm,$destination,$PreviousBackup) -Name $jobName
        }

        $jobPollTime = 15
       $exit = $false
        while (!$exit){
            $jobs = Request-JobStatus
            if ($jobs -eq (Get-JobsCompleteFlag) ){
                $exit = $true
            }
            sleep $jobPollTime       
        }
    
    $outputObj = New-Object -TypeName psobject
    $outputObj | Add-Member -MemberType NoteProperty -Name "BackupInstance" -Value $backupInstant
    $outputObj | Add-Member -MemberType NoteProperty -Name "backupType" -Value $backupType
    $outputObj | Add-Member -MemberType NoteProperty -Name "PreviousBackup" -Value $PreviousBackupPath
    $outputObj | Add-Member -MemberType NoteProperty -Name "IndexSinceLastFull" -Value ($IndexSinceLastFull+1)
    $outputObj | Add-Member -MemberType NoteProperty -Name "Files" -Value $FilesToCopy

    $outputObj | ConvertTo-Json -Depth 5 | Set-Content $outBackupDataPath

    Write-Log "Performing metadata file cleaning"
    $TotalbackupCount = (Get-Content "$anchorBackupDirectory\FC_RootBackup.log" | Measure-Object).Count
    "$BackupInstanceName,$TotalbackupCount" | Add-Content "$anchorBackupDirectory\FC_RootBackup.log"
    $clearLastNBackups = 10
    $numberOfBackupsToDelete = $TotalbackupCount - $clearLastNBackups

    if ($numberOfBackupsToDelete -gt 0) {
        $folders = Get-ChildItem $anchorBackupDirectory | Where-Object { $_.PSIsContainer }
        $numToDelete = ($folders | Measure-Object | select -ExpandProperty Count) - $NumberOfBackupsToKeep
        if($numToDelete -gt 0){
       Write-Log "Deleting the last $numberOfBackupsToDelete backups" 
       $delete =  $folders | sort name -Descending | Select-Object -Last $numToDelete -ExpandProperty FullName
       $delete| Remove-item -Force -Recurse 
       }
       
      Write-Log "Removing the last $numberOfBackupsToDelete from $anchorBackupDirectory\FC_RootBackup.log" Debug
      (Get-Content "$anchorBackupDirectory\FC_RootBackup.log" | Select-Object -Skip $numberOfBackupsToDelete) | Set-Content "$anchorBackupDirectory\FC_RootBackup.log"
    }
    Write-Log "Done cleaning up the metadata file"
    Write-Log "File backup completed."

  }
  catch {
    throw
  }
  finally {
    Set-Location $originalLocation
  }
} Export-ModuleMember -Function Invoke-IncrementalFileBackup
