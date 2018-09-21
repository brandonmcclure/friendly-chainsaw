function Export-ExcelToTxt {
  param(
    [string]$excelFilePath,
    [string]$WorksheetName,
    [string]$csvLoc
  )
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
      Write-Log "Unable to open worksheet $WorksheetName" Error -ErrorAction Stop
    }
    $n = [io.path]::GetFileNameWithoutExtension($excelFilePath) + "_" + $sheet.Name
    $savePath = "$csvLoc\$n.txt"
    $sheet.SaveAs("$savePath",20) #https://msdn.microsoft.com/en-us/library/office/ff198017.aspx

    $E.Quit()
  }
  catch {
    $E.Quit()
    Write-Log "$($_.Exception) " Error
    Write-Log "Error Line: $($_.InvocationInfo.PositionMessage)" Error

    Write-Log "Error of some sorts... closing out the Excel workbook" Error -ErrorAction Stop

  }
} Export-ModuleMember -Function Export-ExcelToTxt