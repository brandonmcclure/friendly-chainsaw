function Import-Excel {
  param(
    [string]$FileName,
    [string]$WorksheetName,
    [switch]$DisplayProgress = $true
  )

  if ($FileName -eq "") {
    throw "Please provide path to the Excel file"
    exit
  }

  if (-not (Test-Path $FileName)) {
    throw "Path '$FileName' does not exist."
    exit
  }

  #$FileName = Resolve-Path $FileName
  $excel = New-Object -ComObject Excel.Application
  $excel.Visible = $false
  $workbook = $excel.workbooks.Open($FileName)

  if (-not $WorksheetName) {
    Write-Warning "Defaulting to the first worksheet in workbook."
    $sheet = $workbook.ActiveSheet
  } else {
    $sheet = $workbook.Sheets.Item($WorksheetName)
  }

  if (-not $sheet)
  {
    throw "Unable to open worksheet $WorksheetName"
    exit
  }

  $sheetName = $sheet.Name
  $columns = $sheet.UsedRange.Columns.count
  $lines = $sheet.UsedRange.Rows.count

  Write-Warning "Worksheet $sheetName contains $columns columns and $lines lines of data"

  $fields = @()

  for ($column = 1; $column -le $columns; $column++) {
    $fieldName = $sheet.Cells.Item.Invoke(1,$column).Value2
    if ($fieldName -eq $null) {
      $fieldName = "Column" + $column.ToString()
    }
    $fields += $fieldName
  }

  $line = 2


  for ($line = 2; $line -le $lines; $line++) {
    $values = New-Object object[] $columns
    for ($column = 1; $column -le $columns; $column++) {
      $values[$column - 1] = $sheet.Cells.Item.Invoke($line,$column).Value2
    }

    $row = New-Object psobject
    $fields | ForEach-Object -Begin { $i = 0 } -Process {
      $row | Add-Member -MemberType noteproperty -Name $fields[$i] -Value $values[$i]; $i++
    }
    $row
    $percents = [math]::Round((($line / $lines) * 100),0)
    if ($DisplayProgress) {
      Write-Progress -Activity:"Importing from Excel file $FileName" -Status:"Imported $line of total $lines lines ($percents%)" -PercentComplete:$percents
    }
  }
  $workbook.Close()
  $excel.Quit()
} Export-ModuleMember -Function Import-Excel