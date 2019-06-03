Function Invoke-SSASTabularMetadataReport{
param($databaseName,$serverName ,$outputFilePath = $env:TEMP)

Import-Module pshtmltable -Force -DisableNameChecking

$dbs = Get-SSASTabularDatabases -serverName $serverName -name $databaseName


$outObjs = @()
foreach ($db in $dbs){
$reportTitle = $null
Write-Log "Checking out $($db.name) database"
$tables = $db | Get-SSASTabularTables
foreach ($table in $tables){
    Write-Log "$($table.name) table" -tabLevel 1
    foreach ($measure in $table.Measures){
        Write-Log "$($measure.name) measure" -tabLevel 2
        $measObj = new-object PSObject
        $measObj | add-member -Type NoteProperty -name TableName -value $t2.Name
        $measObj | add-member -Type NoteProperty -name name -value $measure.Name
        $measObj | add-member -Type NoteProperty -name description -value $measure.Description
        $measObj | add-member -Type NoteProperty -name DisplayFolder -value $measure.DisplayFolder
        $measObj | add-member -Type NoteProperty -name Expression -value $measure.Expression

        $outObjs += $measObj
    }
}
$htlmTable = $outObjs | New-HTMLTable -setAlternating $false 

$reportTitle = "$($db.name) Model documentation"

#Build the HTML head, add an h3 header, add the event table, and close out the HTML
$HTML = New-HTMLHead
$HTML += "<h2>$reportTitle</h2>"
$HTML += ""
$HTML += $htlmTable
$HTML += "<br>"
$HTML = $HTML | Close-HTML

$outData = New-Object PsObject

$jsonPath = "$outputFilePath\$reportTitle.json"
$outData | add-member -type NoteProperty -Name jsonPath -Value $jsonPath
$outObjs | ConvertTo-Json -Depth 5 | out-file $jsonPath

$reportPath = "$outputFilePath\$reportTitle.htm"
$outData | add-member -type NoteProperty -Name reportPath -Value $reportPath
Set-Content $reportPath $HTML
}
#Write-Output $outData
}Export-ModuleMember -Function Invoke-SSASTabularMetadataReport