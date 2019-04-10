function Export-ExcelToTxt {
<#
    .Synopsis
      Saves an excel workbook's worksheet as a windows txt files. 

    .INPUTS
       None
    .OUTPUTS
       The full file path to the flat file
    #>
  param(
    [string]$excelFilePath,
    [string]$WorksheetName,
    [string]$csvLoc,
    $XlFileFormat = 'xlTextWindows'
  )
  #https://msdn.microsoft.com/en-us/library/office/ff198017.aspx
  $ValidXLFileFormats = @{'xlCSV'=6; 'xlTextWindows' = 20}

  if  ($ValidXLFileFormats[$XlFileFormat] -le 0){
        Write-Log "Could not identify which XLFileFormat to use"
    }
    else{
        $XLFileFormatID = $ValidXLFileFormats[$XlFileFormat]
    }

    Write-Log "Using the XLFileFormatID: $XLFileFormatID" Debug
    Write-Log "Exporting the Excel file at: $excelFilePath" Debug 
  $E = New-Object -ComObject Excel.Application
  $E.Visible = $false
  $E.DisplayAlerts = $false
  try {
    $wb = $E.workbooks.Open($excelFilePath,"0","True")
  }
  catch {
    Write-Log "$($_.Exception) " Error
    Write-Log "Error Line: $($_.InvocationInfo.PositionMessage)" Debug
    Write-Log "Error Opening the workbook at $excelFilePath. See log messages above for more info" Error
  }
  try {
    if (-not $WorksheetName) {
      Write-Log "No parameter passed to the worksheetName parameter. Defaulting to the first worksheet in workbook." Debug
      $sheet = $wb.ActiveSheet
    } else {
      Write-Log "Attempting to load the $WorksheetName worksheet." Debug
      $sheet = $wb.Sheets.Item($WorksheetName)
    }
    if (-not $sheet) {
      Write-Log "Unable to open worksheet $sheet" Error -ErrorAction Stop
    }
    $n = [io.path]::GetFileNameWithoutExtension($excelFilePath) + "_" + $sheet.Name
    $savePath = "$csvLoc\$n.txt"
    $sheet.SaveAs("$savePath",$XLFileFormatID) 
    
    Write-Output $savePath
  }
  catch {
    
    Write-Log "$($_.Exception) " Error
    Write-Log "Error Line: $($_.InvocationInfo.PositionMessage)" Error
    Write-Log "Error of some sorts... closing out the Excel workbook" Error -ErrorAction Stop

  }
  finally{
    $E.Quit()
    [Runtime.Interopservices.Marshal]::ReleaseComObject($E) | Out-Null
  }

} Export-ModuleMember -Function Export-ExcelToTxt