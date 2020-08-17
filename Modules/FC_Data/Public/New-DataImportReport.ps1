function New-DataImportReport{
param($objStore,$outputFilePath,$emailTo,$emailFrom,$smtpServer, [switch]$OpenInIE)


#Create the HTML table without alternating rows, colorize Warning and ColumnsInDBNotInFile messages, highlighting the whole row.
$destServerName = $objStore.Files | select -ExpandProperty destServerName -Unique
$destDatabase = $objStore.Files | select -ExpandProperty destDatabase -Unique
$executeScripts = $objStore.executeScripts
$f = $objStore.Files | Sort-Object -Property "FQTableName" -Descending | Select-Object 'FQTableName', 'FileName', @{ N = "numberOfRecordsToLoad"; E = { $_.ImportSummary.numberOfRecordsToLoad } },@{ N = "Warnings"; E = { $_.Warnings -Join ',' } },'ErrorException','ErrorLine','ErrorMessage','ErrorExists'
$eventTable = $f | New-HTMLTable -setAlternating $false -Properties 'FQTableName','FileName','numberOfRecordsToLoad','Warnings','ErrorException','ErrorLine','ErrorMessage','ErrorExists' | Add-HTMLTableColor -Argument "1" -Column "ErrorExists" -AttrValue "background-color:red;" -WholeRow

$reportTitle = "Adhoc Data load $(Get-Date -Format "yyyy.MM.dd_HH.mm.ss")"
#Build the HTML head, add an h3 header, add the event table, and close out the HTML
$HTML = New-HTMLHead
$HTML += "<h2>$reportTitle</h2>"
if ($executeScripts) {
  $HTML += '<font color="red">SQL scripts below have been executed against the ' + "$destDatabase database on the $destServerName instance</font>"
}
else {
  $HTML += '<font color="reb">SQL scripts below have <b>not</b> been executed against the ' + "$destDatabase database on the $destServerName instance</font>"
}
$HTML += $eventTable
$HTML += "<br>"
$HTML += "Create Schema code"
$HTML += "<code><pre>$sqlCreateSchema</pre></code>"
$HTML += "<br>"
$files = $objStore.Files
foreach ($obj in $files) {
  $HTML += "<h2>$($obj.FilePath) Details</h2>"
  $HTML += $obj.fileHTMLReport
  $HTML += "<h3>Create table SQL for database project</h3>"
  $HTML += "<code><pre>$($obj.sqlprojCreateScript)</pre></code>"

  $HTML += "<br>"
}
$HTML = $HTML | Close-HTML


if($OpenInIE){
$reportPath = "$outputFilePath\$reportTitle.htm"
Set-Content $reportPath $HTML
& 'C:\Program Files\Internet Explorer\iexplore.exe' $reportPath
}

if (![string]::IsNullOrEmpty($emailTo)) {
  $emailFrom = $emailFrom
  $s = New-Object System.Security.SecureString
  $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "NT AUTHORITY\ANONYMOUS LOGON",$S
  $SubjectLine = "Lites - ESO Data load report"
  Send-MailMessage -To $emailTo -From $emailFrom -Body $HTML -Subject $SubjectLine -SmtpServer $smtpServer -BodyAsHtml -Credential $creds
}
}Export-ModuleMember -Function New-DataImportReport