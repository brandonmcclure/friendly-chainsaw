Import-Module FC_Core
Function Remove-FilesOlderThan{
<#
    .SYNOPSIS
        Deletes all files older than X (Days,Months or Years), and all empty directories inside of a given directory. This is helpful for managing archived copies of flat files that we send to third parties. 
#> 
[CmdletBinding()]
param( 
    [Parameter(ValueFromPipeline=$True, Position=0)] [string] $directory
    ,[ValidateSet("Days","Months","Years")][string] $DateType
    ,[int] $olderThan = 90
    ,[switch] $areYouSure = $false
    ,[Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Warning"
)
clear
if ([string]::IsNullOrEmpty($directory)){
    Write-Log "The directory parameter cannot be null" error -ErrorAction Stop
}
if ([string]::IsNullOrEmpty($DateType)){
    Write-Log "The DateType parameter cannot be null" error -ErrorAction Stop
}
If (!(Test-Path $directory)){
    Write-Log "Could not find a directory named: $directory" Error -ErrorAction Stop
}
if ($DateType -eq "Days"){
    $timeCriteria = [DateTime]::Now.AddDays(-$olderThan)
}
if ($DateType -eq "Months"){
    $timeCriteria = [DateTime]::Now.AddMonths(-$olderThan)
}
if ($DateType -eq "Years"){
    $timeCriteria = [DateTime]::Now.AddYears(-$olderThan)
}

Write-Log "Searching for all files older than $olderThan $DateType"
$files = Get-ChildItem $directory -File -Recurse | where {$_.LastWriteTime -le $timeCriteria} | Select -ExpandProperty FullName
Write-Log "I found $($files.Count) files"

if ($($files.Count) -gt 0){
    if ($areYouSure){
        Write-Log "You seem to be determined to delete the files, performing the delete on all $($files.Count) files" Warning
        $files | Foreach-Object {
        Write-Log "Removing old file $_" Debug
        Remove-Item $_
        }
    }
    else{
        $files | Foreach-Object {Remove-Item $_ -WhatIf}
    }
}
else{
    Write-Log "No Files found" 
}

Write-Log "Checking for Empty directories"
do {
  $dirs = gci $directory -directory -recurse | Where { (gci $_.fullName).count -eq 0 } | select -expandproperty FullName

  if ($dirs.Count -gt 0){
      if ($areYouSure){
            Write-Log "You seem to be determined to delete the files, performing the delete on all $($dirs.Count) empty directories" Warning
            $dirs | Foreach-Object { 
                Write-Log "Removing empty directory $_" Debug
                Remove-Item $_ 
            }
        }
        else{
            $dirs | Foreach-Object { 
                Remove-Item $_ -WhatIf
            }
            Write-Log "When you are ready to actually delete all $($files.Count) files and $($dirs.Count) empty directories, run this function again with the areYouSure switch" Warning
        }
    }
    else{
        Write-Log "No empty directories found"
    }
} while ($dirs.count -gt 0)




} Export-ModuleMember -Function Remove-FilesOlderThan

Function Get-UserLoggedOn{
    param($computerName = $env:COMPUTERNAME)
    Write-Output (Invoke-Command -ComputerName $computerName -ScriptBlock {Get-Process -IncludeUserName | Where  name -eq "explorer" | Select-Object -Unique -Property UserName} )
}Export-ModuleMember -Function Get-UserLoggedOn