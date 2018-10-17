﻿function SetDataImportSQLMetadata {
  param(
    $a
    ,[System.Data.DataTable]$dataAsDataTable
  )
  $metaDataSQL = "Select count(*) 'cnt' from sys.objects obj
  inner join sys.schemas sch on obj.schema_id = sch.schema_id and sch.name = '$($a.schemaName)'
where obj.name = '$($a.tableName)';"
  $tableMetaData = Invoke-Sqlcmd -ServerInstance $a.destServerName -Database $a.destDatabase -Query $metaDataSQL | Select-Object -ExpandProperty cnt

  $a.sqlprojCreateScript = New-SQLTableStatementFromDataTable -dataTable $dataAsDataTable -FQTableName $a.FQTableName
  #If table does not exist, generate create table sql
  if ($tableMetaData -eq 0) {
    $SQLCreateTable = New-SQLTableStatementFromDataTable -dataTable $dataAsDataTable -FQTableName $a.FQTableName

    $a.sqlCommand = $SQLCreateTable
    $a.ImportSummary.DoesTableNeedToBeCreated = 1
    #Add the XML needed to add these tables to a SSDT database project. IE, We can copy and paste this output into ClarityCustom so that these tables are part of the proper Clarity_Custom database
    $a.sqlprojIncludes += "    <Build Include=`"$schemaName\Tables\$($a.FQTableName).sql`" />"


    $a.fileHTMLReport += "Table does not exist for $([System.Web.HttpUtility]::HtmlEncode($a.FQTableName)). Will create with the SQL below.<br>Include the following in the database project file<br><code><pre>$([System.Web.HttpUtility]::HtmlEncode($a.sqlprojIncludes))</pre></code>"
  }
  #else, check to see if we need to add any columns
  else {


    #Query the database to modify the local DataTable to match the deployed schema. Generate alter scripts to get the deployed shema to match any new columns
    $dbOrdered = @()
    function QueryDB {
      $noChanges = $true
      $dbTableMetaData = Invoke-Sqlcmd -ServerInstance $a.destServerName -Database $a.destDatabase -ConnectionTimeout 0 -Query "select col.name, column_id  from sys.columns col 
  inner join sys.objects obj on col.object_id = obj.object_id and obj.name = '$($a.tableName)'
  inner join sys.schemas sch on obj.schema_id = sch.schema_id and sch.name = '$($a.schemaName)'"
      foreach ($col in $dbTableMetaData) {
        if (!($dataAsDataTable.Columns[$col.Name])) {
          $a.ColumnsInDBNotInFile += $col
          $a.NumColumnsNotInFile += 1
        }

      }
      foreach ($col in $dataAsDataTable.Columns) {
        $columnName = $col.ColumnName
        $a = $dbTableMetaData | Select-Object -ExpandProperty name | Where-Object { $_ -eq $columnName }
        if (!($a -ne $null)) {
          #$noChanges = $false
          Write-Log "$columnName exists in the file but not in the database. Altering table to add new varchar(max) column"
          $InLocalAndNotDB += $col.ColumnName
          $a.ColumnsAddedToDB += $col
          $a.NumColumnsAddedToDB += 1
          $a.sqlCommand += New-AlterSQLTableStatementFromColumn -FQTableName $FQTableName -dataColumn $col
          #Invoke-Sqlcmd -ServerInstance $destServerName -Database $destDatabase -ConnectionTimeout 0 -Query $alterSQL
        }
      }

      if ($noChanges) {
        foreach ($col in $dbTableMetaData) {
          if ($dataAsDataTable.Columns[$col.Name]) {
            $dbOrdered += $col.Name
          }

        }
        $columnIndex = 0
        foreach ($columnName in $dbOrdered)
        {
          $dataAsDataTable.Columns[$columnName].SetOrdinal($columnIndex);
          $columnIndex++;
        }
      }
      else {
        QueryDB }
    }
    QueryDB




    #Write-DataTable -ServerInstance $destServerName -Database $destDatabase -TableName $FQTableName -data $dataAsDataTable
    $a.fileHTMLReport += "<h3>Columns in file and not in database (need to be added to DB)</h3>"
    $a.fileHTMLReport += $a.ColumnsAddedToDB | Sort-Object -Property "Ordinal" | New-HTMLTable -setAlternating $false -Properties ColumnName,DataType,Ordinal
    $a.fileHTMLReport += "<br>"
    $a.fileHTMLReport += "<h4>Columns in database and not in file (will be null with this import)</h4>"
    $a.fileHTMLReport += $a.ColumnsInDBNotInFile | Sort-Object -Property "column_id" | New-HTMLTable -setAlternating $false -Properties name,column_id
  }
} Export-ModuleMember -Function SetDataImportSQLMetadata
