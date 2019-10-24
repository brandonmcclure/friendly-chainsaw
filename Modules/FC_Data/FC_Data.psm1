[int]$Script:MaxJobs = 15
[string]$Script:JobPrefix = 'FC_'
[string]$Script:JobsCompleteFlag = "$($Script:JobPrefix)Complete"
$script:SSISLogLevels = @{ "None" = 0; "Basic" = 1; "Performance" = 2; "Verbose" = 3 }

class iDataImport{
    [boolean]$ErrorExists
    [System.Management.Automation.ErrorRecord]$ErrorException
    [int]$ErrorLine
    [string]$ErrorMessage
}
class DataImportFile:iDataImport {
    [string]$FilePath
    [string]$FileName
    [string]$schemaName
    [string]$tableName
    [string]$FQTableName
    [string]$sqlprojIncludes
    [string]$sqlprojCreateScript
    [string]$sqlCommand
    [string]$destServerName
    [string]$destDatabase
    
    [string]$fileHTMLReport
    [DataImportFileSummary] $ImportSummary    

    DataImportFile(){
        $this.ImportSummary = New-Object DataImportFileSummary
    }
}

class DataImportSummary{
    [int]$numberOfRecordsToLoad
    [int]$numberOfRecordsFailedToLoad

    DataImportSummary(){
        $this.numberOfRecordsToLoad = 0
        $this.numberOfRecordsFailedToLoad = 0
    }
}
class DataImportFileSummary : DataImportSummary{
    [string[]]$ColumnsInDBNotInFile
    [int]$NumColumnsNotInFile
    [string[]]$ColumnsAddedToDB
    [int]$NumColumnsAddedToDB
    [boolean]$DoesTableNeedToBeCreated

    DataImportFileSummary(){
        $this.ColumnsInDBNotInFile = ""
        $this.NumColumnsNotInFile = 0
        $this.ColumnsAddedToDB = ""
        $this.NumColumnsAddedToDB = 0
        $this.DoesTableNeedToBeCreated = $false
    }
}

  class myOut {
  [DataImportFile] $metadata
  [System.Data.DataTable] $DataTable
  }

Write-Verbose "Importing Functions"

# Import everything in sub folders folder 
foreach ($folder in @('private','public','classes'))
{
  $root = Join-Path -Path $PSScriptRoot -ChildPath $folder
  if (Test-Path -Path $root)
  {
    Write-Verbose "processing folder $root"
    $files = Get-ChildItem -Path $root -Filter *.ps1


    # dot source each file 
    $files | Where-Object { $_.Name -notlike '*.Tests.ps1' } |
    ForEach-Object { Write-Verbose $_.Name;.$_.FullName }
  }
}
