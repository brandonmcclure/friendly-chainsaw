[int] $Script:MaxJobs = 15
[string] $Script:JobPrefix = 'FC_'
[string] $Script:JobsCompleteFlag = "$($Script:JobPrefix)Complete"
$script:SSISLogLevels = @{"None" = 0; "Basic" = 1; "Performance" = 2; "Verbose" = 3}

function Get-JobPrefix{
    $Script:JobPrefix
}Export-Modulemember -Function Get-JobPrefix
function Get-SSISLogLevels{
    $script:SSISLogLevels
}Export-ModuleMember -Function Get-SSISLogLevels
function Import-Excel{
  param (
    [string]$FileName,
    [string]$WorksheetName,
    [switch]$DisplayProgress = $true
  )

  if ($FileName -eq "") {
    throw "Please provide path to the Excel file"
    Exit
  }

  if (-not (Test-Path $FileName)) {
    throw "Path '$FileName' does not exist."
    exit
  }

  #$FileName = Resolve-Path $FileName
  $excel = New-Object -comObject Excel.Application
  $excel.Visible = $false
  $workbook = $excel.workbooks.open($FileName)

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
  $columns = $sheet.UsedRange.Columns.Count
  $lines = $sheet.UsedRange.Rows.Count
  
  Write-Warning "Worksheet $sheetName contains $columns columns and $lines lines of data"
  
  $fields = @()
  
  for ($column = 1; $column -le $columns; $column ++) {
    $fieldName = $sheet.Cells.Item.Invoke(1, $column).Value2
    if ($fieldName -eq $null) {
      $fieldName = "Column" + $column.ToString()
    }
    $fields += $fieldName
  }
  
  $line = 2
  
  
  for ($line = 2; $line -le $lines; $line ++) {
    $values = New-Object object[] $columns
    for ($column = 1; $column -le $columns; $column++) {
      $values[$column - 1] = $sheet.Cells.Item.Invoke($line, $column).Value2
    }  
  
    $row = New-Object psobject
    $fields | foreach-object -begin {$i = 0} -process {
      $row | Add-Member -MemberType noteproperty -Name $fields[$i] -Value $values[$i]; $i++
    }
    $row
    $percents = [math]::round((($line/$lines) * 100), 0)
    if ($DisplayProgress) {
      Write-Progress -Activity:"Importing from Excel file $FileName" -Status:"Imported $line of total $lines lines ($percents%)" -PercentComplete:$percents
    }
  }
  $workbook.Close()
  $excel.Quit()
} Export-ModuleMember -Function Import-Excel
Function Export-ExcelToTxt{
[CmdletBinding(SupportsShouldProcess=$true)] 
  param (
    [string]$excelFilePath,
    [string]$WorksheetName,
    [string]$csvLoc
  )
    $E = New-Object -ComObject Excel.Application
    $E.Visible = $false
    $E.DisplayAlerts = $false
        try{
            $wb = $E.Workbooks.Open($excelFilePath,"0","True")
        }
        catch{
            Write-Log "$($_.Exception) " Error
            Write-Log "Error Line: $($_.InvocationInfo.PositionMessage)" Debug
            Write-Log "Error Opening the workbook at $excelFilePath. See log messages above for more info" Error
            }
        try{
            if (-not $WorksheetName) {
                Write-Log "No parameter passed to the worksheetName parameter. Defaulting to the first worksheet in workbook." Debug
                $sheet = $wb.ActiveSheet
            } else {
                Write-Log "Attempting to load the $WorksheetName worksheet." Debug
                $sheet = $wb.Sheets.Item($WorksheetName)
            }
  
            if (-not $sheet){
                Write-Log "Unable to open worksheet $WorksheetName" Error -ErrorAction Stop
              }
                    $n = [io.path]::GetFileNameWithoutExtension($excelFilePath) + "_" + $sheet.Name
                    $savePath = "$csvLoc\$n.txt"
                    $sheet.SaveAs("$savePath", 20) #https://msdn.microsoft.com/en-us/library/office/ff198017.aspx
    
                $E.Quit()
                }
                catch{
                    $E.Quit()
                    Write-Log "$($_.Exception) " Error
                    Write-Log "Error Line: $($_.InvocationInfo.PositionMessage)" Error
        
                     Write-Log "Error of some sorts... closing out the Excel workbook" Error -ErrorAction Stop
         
    }
}Export-ModuleMember -Function Export-ExcelToTxt
function Join-Object{
    <#
    .SYNOPSIS
        Join data from two sets of objects based on a common value

    .DESCRIPTION
        Join data from two sets of objects based on a common value

        For more details, see the accompanying blog post:
            http://ramblingcookiemonster.github.io/Join-Object/

        For even more details,  see the original code and discussions that this borrows from:
            Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections
            Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

    .PARAMETER Left
        'Left' collection of objects to join.  You can use the pipeline for Left.

        The objects in this collection should be consistent.
        We look at the properties on the first object for a baseline.
    
    .PARAMETER Right
        'Right' collection of objects to join.

        The objects in this collection should be consistent.
        We look at the properties on the first object for a baseline.

    .PARAMETER LeftJoinProperty
        Property on Left collection objects that we match up with RightJoinProperty on the Right collection

    .PARAMETER RightJoinProperty
        Property on Right collection objects that we match up with LeftJoinProperty on the Left collection

    .PARAMETER LeftProperties
        One or more properties to keep from Left.  Default is to keep all Left properties (*).

        Each property can:
            - Be a plain property name like "Name"
            - Contain wildcards like "*"
            - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}.
                 Name is the output property name
                 Expression is the property value ($_ as the current object)
                
                 Alternatively, use the Suffix or Prefix parameter to avoid collisions
                 Each property using this hashtable syntax will be excluded from suffixes and prefixes

    .PARAMETER RightProperties
        One or more properties to keep from Right.  Default is to keep all Right properties (*).

        Each property can:
            - Be a plain property name like "Name"
            - Contain wildcards like "*"
            - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}.
                 Name is the output property name
                 Expression is the property value ($_ as the current object)
                
                 Alternatively, use the Suffix or Prefix parameter to avoid collisions
                 Each property using this hashtable syntax will be excluded from suffixes and prefixes

    .PARAMETER Prefix
        If specified, prepend Right object property names with this prefix to avoid collisions

        Example:
            Property Name                   = 'Name'
            Suffix                          = 'j_'
            Resulting Joined Property Name  = 'j_Name'

    .PARAMETER Suffix
        If specified, append Right object property names with this suffix to avoid collisions

        Example:
            Property Name                   = 'Name'
            Suffix                          = '_j'
            Resulting Joined Property Name  = 'Name_j'

    .PARAMETER Type
        Type of join.  Default is AllInLeft.

        AllInLeft will have all elements from Left at least once in the output, and might appear more than once
          if the where clause is true for more than one element in right, Left elements with matches in Right are
          preceded by elements with no matches.
          SQL equivalent: outer left join (or simply left join)

        AllInRight is similar to AllInLeft.
        
        OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
          match in Right.
          SQL equivalent: inner join (or simply join)
         
        AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
          in right with at least one match in left, followed by all entries in Right with no matches in left, 
          followed by all entries in Left with no matches in Right.
          SQL equivalent: full join

    .EXAMPLE
        #
        #Define some input data.

        $l = 1..5 | Foreach-Object {
            [pscustomobject]@{
                Name = "jsmith$_"
                Birthday = (Get-Date).adddays(-1)
            }
        }

        $r = 4..7 | Foreach-Object{
            [pscustomobject]@{
                Department = "Department $_"
                Name = "Department $_"
                Manager = "jsmith$_"
            }
        }

        #We have a name and Birthday for each manager, how do we find their department, using an inner join?
        Join-Object -Left $l -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type OnlyIfInBoth -RightProperties Department


            # Name    Birthday             Department  
            # ----    --------             ----------  
            # jsmith4 4/14/2015 3:27:22 PM Department 4
            # jsmith5 4/14/2015 3:27:22 PM Department 5

    .EXAMPLE  
        #
        #Define some input data.

        $l = 1..5 | Foreach-Object {
            [pscustomobject]@{
                Name = "jsmith$_"
                Birthday = (Get-Date).adddays(-1)
            }
        }

        $r = 4..7 | Foreach-Object{
            [pscustomobject]@{
                Department = "Department $_"
                Name = "Department $_"
                Manager = "jsmith$_"
            }
        }

        #We have a name and Birthday for each manager, how do we find all related department data, even if there are conflicting properties?
        $l | Join-Object -Right $r -LeftJoinProperty Name -RightJoinProperty Manager -Type AllInLeft -Prefix j_

            # Name    Birthday             j_Department j_Name       j_Manager
            # ----    --------             ------------ ------       ---------
            # jsmith1 4/14/2015 3:27:22 PM                                    
            # jsmith2 4/14/2015 3:27:22 PM                                    
            # jsmith3 4/14/2015 3:27:22 PM                                    
            # jsmith4 4/14/2015 3:27:22 PM Department 4 Department 4 jsmith4  
            # jsmith5 4/14/2015 3:27:22 PM Department 5 Department 5 jsmith5  

    .EXAMPLE
        #
        #Hey!  You know how to script right?  Can you merge these two CSVs, where Path1's IP is equal to Path2's IP_ADDRESS?
        
        #Get CSV data
        $s1 = Import-CSV $Path1
        $s2 = Import-CSV $Path2

        #Merge the data, using a full outer join to avoid omitting anything, and export it
        Join-Object -Left $s1 -Right $s2 -LeftJoinProperty IP_ADDRESS -RightJoinProperty IP -Prefix 'j_' -Type AllInBoth |
            Export-CSV $MergePath -NoTypeInformation

    .EXAMPLE
        #
        # "Hey Warren, we need to match up SSNs to Active Directory users, and check if they are enabled or not.
        #  I'll e-mail you an unencrypted CSV with all the SSNs from gmail, what could go wrong?"
        
        # Import some SSNs. 
        $SSNs = Import-CSV -Path D:\SSNs.csv

        #Get AD users, and match up by a common value, samaccountname in this case:
        Get-ADUser -Filter "samaccountname -like 'wframe*'" |
            Join-Object -LeftJoinProperty samaccountname -Right $SSNs `
                        -RightJoinProperty samaccountname -RightProperties ssn `
                        -LeftProperties samaccountname, enabled, objectclass

    .NOTES
        This borrows from:
            Dave Wyatt's Join-Object - http://powershell.org/wp/forums/topic/merging-very-large-collections/
            Lucio Silveira's Join-Object - http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx

        Changes:
            Always display full set of properties
            Display properties in order (left first, right second)
            If specified, add suffix or prefix to right object property names to avoid collisions
            Use a hashtable rather than ordereddictionary (avoid case sensitivity)

    .LINK
        http://ramblingcookiemonster.github.io/Join-Object/

    .FUNCTIONALITY
        PowerShell Language

    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine = $true)]
        [object[]] $Left,

        # List to join with $Left
        [Parameter(Mandatory=$true)]
        [object[]] $Right,

        [Parameter(Mandatory = $true)]
        [string] $LeftJoinProperty,

        [Parameter(Mandatory = $true)]
        [string] $RightJoinProperty,

        [object[]]$LeftProperties = '*',

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [object[]]$RightProperties = '*',

        [validateset( 'AllInLeft', 'OnlyIfInBoth', 'AllInBoth', 'AllInRight')]
        [Parameter(Mandatory=$false)]
        [string]$Type = 'AllInLeft',

        [string]$Prefix,
        [string]$Suffix
    )
    Begin
    {
        function AddItemProperties($item, $properties, $hash)
        {
            if ($null -eq $item)
            {
                return
            }

            foreach($property in $properties)
            {
                $propertyHash = $property -as [hashtable]
                if($null -ne $propertyHash)
                {
                    $hashName = $propertyHash["name"] -as [string]         
                    $expression = $propertyHash["expression"] -as [scriptblock]

                    $expressionValue = $expression.Invoke($item)[0]
            
                    $hash[$hashName] = $expressionValue
                }
                else
                {
                    foreach($itemProperty in $item.psobject.Properties)
                    {
                        if ($itemProperty.Name -like $property)
                        {
                            $hash[$itemProperty.Name] = $itemProperty.Value
                        }
                    }
                }
            }
        }

        function TranslateProperties
        {
            [cmdletbinding()]
            param(
                [object[]]$Properties,
                [psobject]$RealObject,
                [string]$Side)

            foreach($Prop in $Properties)
            {
                $propertyHash = $Prop -as [hashtable]
                if($null -ne $propertyHash)
                {
                    $hashName = $propertyHash["name"] -as [string]         
                    $expression = $propertyHash["expression"] -as [scriptblock]

                    $ScriptString = $expression.tostring()
                    if($ScriptString -notmatch 'param\(')
                    {
                        Write-Verbose "Property '$HashName'`: Adding param(`$_) to scriptblock '$ScriptString'"
                        $Expression = [ScriptBlock]::Create("param(`$_)`n $ScriptString")
                    }
                
                    $Output = @{Name =$HashName; Expression = $Expression }
                    Write-Verbose "Found $Side property hash with name $($Output.Name), expression:`n$($Output.Expression | out-string)"
                    $Output
                }
                else
                {
                    foreach($ThisProp in $RealObject.psobject.Properties)
                    {
                        if ($ThisProp.Name -like $Prop)
                        {
                            Write-Verbose "Found $Side property '$($ThisProp.Name)'"
                            $ThisProp.Name
                        }
                    }
                }
            }
        }

        function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties)
        {
            $properties = @{}

            AddItemProperties $leftItem $leftProperties $properties
            AddItemProperties $rightItem $rightProperties $properties

            New-Object psobject -Property $properties
        }

        #Translate variations on calculated properties.  Doing this once shouldn't affect perf too much.
        foreach($Prop in @($LeftProperties + $RightProperties))
        {
            if($Prop -as [hashtable])
            {
                foreach($variation in ('n','label','l'))
                {
                    if(-not $Prop.ContainsKey('Name') )
                    {
                        if($Prop.ContainsKey($variation) )
                        {
                            $Prop.Add('Name',$Prop[$Variation])
                        }
                    }
                }
                if(-not $Prop.ContainsKey('Name') -or $Prop['Name'] -like $null )
                {
                    Throw "Property is missing a name`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                }


                if(-not $Prop.ContainsKey('Expression') )
                {
                    if($Prop.ContainsKey('E') )
                    {
                        $Prop.Add('Expression',$Prop['E'])
                    }
                }
            
                if(-not $Prop.ContainsKey('Expression') -or $Prop['Expression'] -like $null )
                {
                    Throw "Property is missing an expression`n. This should be in calculated property format, with a Name and an Expression:`n@{Name='Something';Expression={`$_.Something}}`nAffected property:`n$($Prop | out-string)"
                }
            }        
        }

        $leftHash = @{}
        $rightHash = @{}

        # Hashtable keys can't be null; we'll use any old object reference as a placeholder if needed.
        $nullKey = New-Object psobject
        
        $bound = $PSBoundParameters.keys -contains "InputObject"
        if(-not $bound)
        {
            [System.Collections.ArrayList]$LeftData = @()
        }
    }
    Process
    {
        #We pull all the data for comparison later, no streaming
        if($bound)
        {
            $LeftData = $Left
        }
        Else
        {
            foreach($Object in $Left)
            {
                [void]$LeftData.add($Object)
            }
        }
    }
    End
    {
        foreach ($item in $Right)
        {
            $key = $item.$RightJoinProperty

            if ($null -eq $key)
            {
                $key = $nullKey
            }

            $bucket = $rightHash[$key]

            if ($null -eq $bucket)
            {
                $bucket = New-Object System.Collections.ArrayList
                $rightHash.Add($key, $bucket)
            }

            $null = $bucket.Add($item)
        }

        foreach ($item in $LeftData)
        {
            $key = $item.$LeftJoinProperty

            if ($null -eq $key)
            {
                $key = $nullKey
            }

            $bucket = $leftHash[$key]

            if ($null -eq $bucket)
            {
                $bucket = New-Object System.Collections.ArrayList
                $leftHash.Add($key, $bucket)
            }

            $null = $bucket.Add($item)
        }

        $LeftProperties = TranslateProperties -Properties $LeftProperties -Side 'Left' -RealObject $LeftData[0]
        $RightProperties = TranslateProperties -Properties $RightProperties -Side 'Right' -RealObject $Right[0]

        #I prefer ordered output. Left properties first.
        [string[]]$AllProps = $LeftProperties

        #Handle prefixes, suffixes, and building AllProps with Name only
        $RightProperties = foreach($RightProp in $RightProperties)
        {
            if(-not ($RightProp -as [Hashtable]))
            {
                Write-Verbose "Transforming property $RightProp to $Prefix$RightProp$Suffix"
                @{
                    Name="$Prefix$RightProp$Suffix"
                    Expression=[scriptblock]::create("param(`$_) `$_.'$RightProp'")
                }
                $AllProps += "$Prefix$RightProp$Suffix"
            }
            else
            {
                Write-Verbose "Skipping transformation of calculated property with name $($RightProp.Name), expression:`n$($RightProp.Expression | out-string)"
                $AllProps += [string]$RightProp["Name"]
                $RightProp
            }
        }

        $AllProps = $AllProps | Select -Unique

        Write-Verbose "Combined set of properties: $($AllProps -join ', ')"

        foreach ( $entry in $leftHash.GetEnumerator() )
        {
            $key = $entry.Key
            $leftBucket = $entry.Value

            $rightBucket = $rightHash[$key]

            if ($null -eq $rightBucket)
            {
                if ($Type -eq 'AllInLeft' -or $Type -eq 'AllInBoth')
                {
                    foreach ($leftItem in $leftBucket)
                    {
                        WriteJoinObjectOutput $leftItem $null $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
            else
            {
                foreach ($leftItem in $leftBucket)
                {
                    foreach ($rightItem in $rightBucket)
                    {
                        WriteJoinObjectOutput $leftItem $rightItem $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
        }

        if ($Type -eq 'AllInRight' -or $Type -eq 'AllInBoth')
        {
            foreach ($entry in $rightHash.GetEnumerator())
            {
                $key = $entry.Key
                $rightBucket = $entry.Value

                $leftBucket = $leftHash[$key]

                if ($null -eq $leftBucket)
                {
                    foreach ($rightItem in $rightBucket)
                    {
                        WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties | Select $AllProps
                    }
                }
            }
        }
    }
}export-modulemember -function Join-Object
function Get-JoinedObjectValueHashes{
<#
    .Synopsis
       Use in conjunction with Join-Object to identify if both of the joined objects have the same member names
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       What sort of pipeline inputdoes this expect?
    .OUTPUTS
       What sort of pipeline output does this output?
    .LINK
       www.google.com
    #>
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = $null, [PSObject] $obj, [string] $joinPrefix, [string] $PrimaryKey, [switch] $writeProgress)
    
    $oldLogLevel = Get-LogLevel
    if (!([string]::IsNullOrEmpty($logLevel))){Set-LogLevel $logLevel}
    
    $leftMembers = $obj | Get-Member | where {$_.MemberType -eq "NoteProperty" -and $_.name -notlike "$joinPrefix*" -and $_.name -ne 'ItemArray'} | select Name
    $rightMembers = $obj | Get-Member | where {$_.MemberType -eq "NoteProperty" -and $_.name -like "$joinPrefix*"-and $_.name -ne 'ItemArray'}| select Name
    $outputValue = @()

    if ([string]::IsNullOrEmpty($PrimaryKey)){
        Write-Log "Please pass a value to the PrimaryKey parameter" Error -ErrorAction Stop
    }
    if ([string]::IsNullOrEmpty($joinPrefix)){
        Write-Log "Please pass a value to the joinPrefix parameter" Error -ErrorAction Stop
    }
    $totalRecords = $obj.Count
    $counter = 0
    foreach ($record in $obj){
        $outputObject = New-Object System.Object
        $outputObject | Add-Member -Type NoteProperty -Name 'RecordPK' -Value $record.$PrimaryKey
        $outputObject | Add-Member -Type NoteProperty -Name 'NotMatchedJSON' -Value ""

        foreach ($member in $leftMembers.Name){
            Write-log "Hashing the values for the $member member." Debug
            Write-Log "record.member $record.$member" Debug
            $NotMatchedJSON = "{"
            #Hash the values on the left side
            if ([string]::IsNullOrEmpty($($record.$member))){
                $hashValue = ''
            }
            else{
                $leftHashValue = Get-StringHash -inputString $($record.$member) -ErrorAction SilentlyContinue 
            }

            #hash values on the right and compare
            $rightMemberName = "$joinPrefix$member"

            if ([string]::IsNullOrEmpty($record.$rightMemberName)){
                $hashValue = ''
            }
            else{
                $rightHashValue = Get-StringHash -inputString $record.$rightMemberName -ErrorAction SilentlyContinue 
            }

            if ($leftHashValue -ne $rightHashValue){
                if ($NotMatchedJSON -ne "{"){
                    $NotMatchedJSON += ",""LeftPrimaryKey"":""$record.$PrimaryKey"",""RightPrimaryKey"":""$record.$joinPrefix$PrimaryKey"",""$($member)"":""$($record.$member)"",""$rightMemberName"":""$($record.$rightMemberName)"""
                }
                else{
                    $NotMatchedJSON +=  """LeftPrimaryKey"":""$record.$PrimaryKey"",""RightPrimaryKey"":""$record.$joinPrefix$PrimaryKey"",""$($member)"":""$($record.$member)"",""$rightMemberName"":""$($record.$rightMemberName)"""
                }
            }
        
        $NotMatchedJSON += "}"
        $outputObject.NotMatchedJSON = $NotMatchedJSON
        $outputValue += $outputObject
        }

        if ($writeProgress){
            $counter++
            $pctComplete = ($counter/$totalRecords*100)
            Write-Progress -Activity "Hashing Records" -PercentComplete $pctComplete -Status "Working - $pctComplete%"
        }
        }
    Set-LogLevel $oldLogLevel
    return $outputValue
}export-modulemember -function Get-JoinedObjectValueHashes
function Compare-JoinedObjectMembers{
<#
    .Synopsis
       Use in conjunction with Join-Object to identify if both of the joined objects have the same member names
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER logLevel
        explain your parameters here. Create a new .PARAMETER line for each parameter,
       
    .EXAMPLE
        THis example runs the script with a change to the logLevel parameter.

        .Template.ps1 -logLevel Debug

    .INPUTS
       What sort of pipeline inputdoes this expect?
    .OUTPUTS
       What sort of pipeline output does this output?
    .LINK
       www.google.com
    #>
param([PSObject] $obj, [string] $joinPrefix)
    $leftMembers = $obj | Get-Member | where {$_.MemberType -eq "NoteProperty" -and $_.name -notlike "$joinPrefix*"} | select Name
    $rightMembers = $obj | Get-Member | where {$_.MemberType -eq "NoteProperty" -and $_.name -like "$joinPrefix*"}| select Name
    $outputValue = @()
    foreach ($member in $leftMembers.Name){
        Write-Log "Evaluating the $member property for a coredsponding property that named: $joinPrefix$member " Debug
        $found = 0
        foreach ($rightMember in $rightMembers.Name){
            if  ($($rightMember.replace($joinPrefix,'')) -eq $member){
                $found = 1
            }
        }
        if ($found -eq 0){
            $outputValue += $member
        }
    }

    return $outputValue
}export-ModuleMember -Function Compare-JoinedObjectMembers
function Get-JobsCompleteFlag{
    $Script:JobsCompleteFlag
}Export-modulemember -Function Get-JobsCompleteFlag
function Request-JobStatus{
<#
    .Synopsis
       Used to poll the Powershell Jobs running under the current script scope. Will Write-Log the results from completed jobs, and then remove them. Will return $true when there are no more jobs.  
    .DESCRIPTION
       
    .EXAMPLE
        The below code will check the jobs every 15 seconds untill all the running jobs have completed. 
        $jobPollTime = 15
       $exit = $false
        while ($exit -eq $false){
            $exit = Check-JobStatus
            sleep $jobPollTime       
        }
    #>
    param([string]$nameLike = $null
,[switch] $clearFailed)

        $results = $null
        if ([string]::IsNullOrEmpty(($nameLike))){
            $jobs =  Get-Job | where {$_.name -like "$($Script:JobPrefix)$nameLike*"}
            $compJobs = $jobs | Where State -eq "Completed"
        }
        else{
            $jobs =  Get-Job | where {$_.name -like "$($Script:JobPrefix)$nameLike*"}
            $compJobs = $jobs | Where {$_.State -eq "Completed"}
        }

        Write-Log "[Request-JobStatus]     $($jobs.Count) Jobs have not been recieved. $($compJobs.Count) Jobs have been completed and will be recieved." Debug
        if ($($jobs.Count) -eq 0 ){
            $results = Get-JobsCompleteFlag
        }
        if($clearFailed){
            $failedJobs = $jobs | Where {$_.State -eq "Failed"}
            Write-Log "[Request-JobStatus]     Clearing $($failedJobs.Count) jobs that have failed" Debug
            foreach ($job in $failedJobs){
                $job | Remove-Job
            }
        }
        if( $jobs.Count -eq 0 ){
            Write-Log "[Request-JobStatus]     All jobs complete" Debug
            $results = Get-JobsCompleteFlag
        }
        foreach($job in $compJobs){
            Write-Log "[Request-JobStatus]     ----------" Debug
            Write-Log "[Request-JobStatus]     Recieving job: $($job.Name)" Debug
            $results = $job | Receive-Job 
            $job | Remove-Job
        }
          
        Write-Output $results 
}export-modulemember -function Request-JobStatus
function Get-MyJobs{
<#
    .Synopsis
        Returns a list of jobs using the managaed job names.
    .DESCRIPTION
      Returns an array of jobs that have the name like "$Script:JobPrefix*", and the specified status.If no status is specified, returns all jobs. This is used in the FC job framework when polling for finished jobs.  
    .OUTPUTS
       An array of powershell background job objects. or null
    #>
param([Parameter(position=0)][string[]]$state)

$returnValue = $null
if ($state -eq $null){
    $returnValue = (Get-Job | Where-Object $_.Name -like "$Script:JobPrefix*")
}
else{
    $returnValue = (Get-Job | Where { $state -contains $_.state -and $_.Name -like "$Script:JobPrefix*"})
}

Write-Output $returnValue

}export-modulemember -function Get-MyJobs
function Start-MySQLQueryJob{
param([string] $JobSuffix
,[string] $sqlServer
,[string] $sqlDatabase = $null
,[string] $sqlQuery = $null
,[PSCredential] $jobCreds = $null)

if ([string]::IsNullOrEmpty($sqlQuery)){
    Write-Log "Please pass a query using the sqlQuery parameter" Error -ErrorAction Stop
}
if ([string]::IsNullOrEmpty($JobSuffix)){
    $JobSuffix = Get-StringHash $sqlQuery -hashAlgo SHA1
}
write-log "sqlServer: $sqlServer" Debug
write-log "sqlDatabase: $sqlDatabase" Debug
write-log "sqlQuery: $sqlQuery" Debug

$running = Get-MyJobs -state 'Running'
    if ($running.Count -le $Script:MaxJobs){
        Write-Log "[Start-MySQLQueryJob] Starting job named $Script:JobPrefix$JobSuffix"	Debug
        #If credentials are specified create the Invoke-SQLcmd job with them
        if ($jobCreds -eq $null){
            Start-Job -ScriptBlock {
		        param($jobQuery,$sqlServer, $sqlDatabase)
                 $results = Invoke-Sqlcmd -Query $jobQuery -ServerInstance $sqlServer -Database $sqlDatabase 
                 $results
            } -ArgumentList ($sqlQuery,$sqlServer,$sqlDatabase) -Name "$Script:JobPrefix$JobSuffix"
        }
        else{	
	        Start-Job -ScriptBlock {
		        param($jobQuery,$sqlServer, $sqlDatabase)
                 $results = Invoke-Sqlcmd -Query $jobQuery -ServerInstance $sqlServer -Database $sqlDatabase 
                 $results
            } -ArgumentList ($sqlQuery,$sqlServer,$sqlDatabase) -Name "FC_$JobSuffix" -Credential $jobCreds 
        }
        $true 
    }
    else{
        $false
    }
}Export-ModuleMember -function Start-MySQLQueryJob
function Query-SqlWithCache{
    <#
    .Synopsis
        Wrapper for Invoke-SQLCmd cmdlt which has some error handling, server name resolution, and optional local caching. 
    .DESCRIPTION
      The local caching does not clean up files, so we will want to delete them manually, and of course use the utmost caution/discretion when working with any PHI. 

    .PARAMETER Environment
        What clarity environment do you want to query? This drives the server that will be used, and the database name. Valid options:"POC","TST","PRD","RELVAL"
    .PARAMETER query
        The sql query to execute
    .PARAMETER CustomDB
        A switch that when specified, changes the DB name to Clarity_Custom_$Environment. Since our Custom/RPT databases are on the same servers you could also use fully qualified object names in your query to access objects in custom. 
     .PARAMETER CacheResultsLocally
        A switch that when specified will locally cache data to speed up subsequent queries
    .PARAMETER cacheDir
        A directory that the xml files that store the cached data will be stored in. Default is C:\temp
        YOU NEED TO CLEAN THESE FILES UP YOUR SELF!!!
    .PARAMETER cacheDays
        A integer that specifies how old a file can be before the local cache is refreashed. Default is -1 (1 day old) 

        Set this to a positive number to force a refreash of the local cache. 

    .EXAMPLE
        Run a basic query, and return an array of DataRows. 

        $results = "select * from dbo.Report_desc" | Query-Clarity POC
     .EXAMPLE
        Store a copy of the data locally to speed up any other queries. 
        The local cache will be located: C:\temp\$serverName$DatabaseName_$queryHash
        ie: (EPWCOGSQL01Clarity_POC_145868016216295781216920420294223571441041221777622495882505022372121155874110212)

        the function will use this cache object until it is older than 1 day. 
         
        $results = "select * from dbo.Report_desc" | Query-Clarity POC -CacheResultsLocally
    .EXAMPLE
        Store a copy of the data locally to speed up any other queries. Overriding defaults to use the local cache for longer than 1 day, and use a different directory

        -cacheDir is where the XML files will be created. Specifing it overrides the default directory of C:\temp\ 
        -cacheDays will refreash the local cache if it is older than 5 days. 
         
        $results = "select * from dbo.Report_desc" | Query-Clarity POC -CacheResultsLocally -cacheDir C:\myDir\ -cacheDays -5
    .EXAMPLE
        Store a copy of the data locally to speed up any other queries. Forces a re-cache of the local data

        Specify any number greater than 0 to -cacheDays.
         
        $results = "select * from dbo.Report_desc" | Query-Clarity POC -CacheResultsLocally -cacheDays 1

    .INPUTS
       A sql command
    .OUTPUTS
       A array of System.Data.DataRow. 
       The DataRow objects will have Properties that corespond to the columns returned by your data set.  
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Warning",[string] $ServerInstance
,[string] $Database
,[Parameter(position=1,ValueFromPipeline)][string] $query = $null
,[string] $cacheDir = "C:\temp\"
,[int] $cacheDays = -1
)
$currentLogLevel = Get-LogLevel
if (!([string]::IsNullOrEmpty($logLevel))){
        Set-LogLevel $logLevel
    }
    
Write-Log "ServerName : $ServerInstance" Debug
Write-Log "Database: $Database" Debug

$queryStartTime = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module BrandonLib
$queryHash = Get-StringHash $query
$fqPath = "$cacheDir$ServerInstance$($Database)_$queryHash.xml"
if (!(Test-Path  $fqPath)){
    Write-Log "Data is not cached, loading cache. File path: $fqPath" Debug
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query -QueryTimeout 0 -ConnectionTimeout 0
    $results | Export-Clixml -Path $fqPath
}
elseif( $(Get-ChildItem $fqPath).LastWriteTime -le (Get-Date).AddDays($cacheDays)){
    Write-Log "Refreashing local cache. File path: $fqPath" Debug
    Remove-item $fqPath
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $query -QueryTimeout 0 -ConnectionTimeout 0
    $results | Export-Clixml -Path $fqPath
}
else{
    Write-Log "Using local cache. File path: $fqPath" Debug
    $results = Import-Clixml $fqPath
}
$elapsedTime = $queryStartTime.ElapsedMilliseconds
Write-Log "Query took: $elapsedTime miliseconds" Debug
Set-LogLevel $currentLogLevel
$results

}Export-ModuleMember -function Query-SqlWithCache
function Start-SSASXEventTrace{
param([String] $instanceName = $null
,[string][ValidateSet("CogitoASTrace_Basic", "CogitoASTrace_Verbose")] $TraceType = "CogitoASTrace_Basic"
)

Import-Module FC_Log, FC_Core -Force -DisableNameChecking

if ([string]::IsNullOrEmpty($instanceName)){
    Write-Log "Please pass a instance name to the instanceName parameter" Error -ErrorAction Stop
}



<# See if trace is running, exit if it is #>
[xml]$Traces = Invoke-ASCmd -Query 'SELECT * FROM $system.discover_traces' -Server $instanceName
foreach ($row in $Traces.FirstChild.ChildNodes.row)
    {
    if ($row.TraceName -eq "CogitoASTrace")
        { 
            Write-Log "Trace is already running, aborting"
        exit 
        }
    }

$exEventDir = "F:\ExtendedEvents\$($instanceName.Replace("\","_"))"

if ($TraceType -eq "CogitoASTrace_Basic"){
    $traceQuery = @"
    <Create
    xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2"
    xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2"
    xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100"
    xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200"
    xmlns:ddl300_300="http://schemas.microsoft.com/analysisservices/2011/engine/300/300">
	    <ObjectDefinition>
		    <Trace>
			    <ID>CogitoASTrace</ID>
			    <Name>CogitoASTrace</Name>
			    <ddl300_300:XEvent>
				    <event_session name="CogitoASTrace" dispatchLatency="1" maxEventSize="4" maxMemory="4"
				     memoryPartitionMode="none" eventRetentionMode="allowSingleEventLoss"
				     trackCausality="true">
					    <!-- ### COMMAND EVENTS ### -->
					    <!--<event package="AS" name="CommandBegin" />-->
					    <event package="AS" name="CommandEnd" />

					    <!-- ### DISCOVER EVENTS ### -->
					    <!--<event package="AS" name="DiscoverBegin" />-->
					    <!--<event package="AS" name="DiscoverEnd" />-->

					    <!-- ### DISCOVER SERVER STATE EVENTS ### -->
					    <!--<event package="AS" name="ServerStateDiscoverBegin" />-->
					    <!--<event package="AS" name="ServerStateDiscoverEnd" />-->

					    <!-- ### ERRORS AND WARNING ### -->
					    <event package="AS" name="Error" />

					    <!-- ### FILE LOAD AND SAVE ### -->
					    <!--<event package="AS" name="FileLoadBegin" />-->
					    <!--<event package="AS" name="FileLoadEnd" />-->
					    <!--<event package="AS" name="FileSaveBegin" />-->
					    <!--<event package="AS" name="FileSaveEnd" />-->
					    <!--<event package="AS" name="PageInBegin" />-->
					    <!--<event package="AS" name="PageInEnd" />-->
					    <!--<event package="AS" name="PageOutBegin" />-->
					    <!--<event package="AS" name="PageOutEnd" />-->

					    <!-- ### LOCKS ### -->
					    <event package="AS" name="Deadlock" />
					    <event package="AS" name="LockAcquired" />
					    <event package="AS" name="LockReleased" />
					    <event package="AS" name="LockTimeout" />
					    <!--<event package="AS" name="LockWaiting" />-->

					    <!-- ### NOTIFICATION EVENTS ### -->
					    <!--<event package="AS" name="Notification" />-->
					    <!--<event package="AS" name="UserDefined" />-->

					    <!-- ### PROGRESS REPORTS ### -->
					    <event package="AS" name="ProgressReportBegin" />
					    <!--<event package="AS" name="ProgressReportCurrent" />-->
					    <event package="AS" name="ProgressReportEnd" />
					    <event package="AS" name="ProgressReportError" />

					    <!-- ### QUERY EVENTS ### -->
					    <event package="AS" name="QueryBegin" />
					    <event package="AS" name="QueryEnd" />

					    <!-- ### QUERY PROCESSING ### -->
					    <!--<event package="AS" name="CalculateNonEmptyBegin" />-->
					    <!--<event package="AS" name="CalculateNonEmptyCurrent" />-->
					    <!--<event package="AS" name="CalculateNonEmptyEnd" />-->
					    <!--<event package="AS" name="CalculationEvaluation" />-->
					    <!--<event package="AS" name="CalculationEvaluationDetailedInformation" />-->
					    <!--<event package="AS" name="DaxQueryPlan" />-->
					    <!--<event package="AS" name="DirectQueryBegin" />-->
					    <!--<event package="AS" name="DirectQueryEnd" />-->
					    <!--<event package="AS" name="ExecuteMDXScriptBegin" />-->
					    <!--<event package="AS" name="ExecuteMDXScriptCurrent" />-->
					    <!--<event package="AS" name="ExecuteMDXScriptEnd" />-->
					    <event package="AS" name="GetDataFromAggregation" />
					    <event package="AS" name="GetDataFromCache" />
					    <event package="AS" name="QueryCubeBegin" />
					    <event package="AS" name="QueryCubeEnd" />
					    <event package="AS" name="QueryDimension" />
					    <event package="AS" name="QuerySubcube" />
					    <event package="AS" name="ResourceUsage" />-->
					    <event package="AS" name="QuerySubcubeVerbose" />
					    <!--<event package="AS" name="SerializeResultsBegin" />-->
					    <!--<event package="AS" name="SerializeResultsCurrent" />-->
					    <!--<event package="AS" name="SerializeResultsEnd" />-->
					    <!--<event package="AS" name="VertiPaqSEQueryBegin" />-->
					    <!--<event package="AS" name="VertiPaqSEQueryCacheMatch" />-->
					    <!--<event package="AS" name="VertiPaqSEQueryEnd" />-->

					    <!-- ### SECURITY AUDIT ### -->
					    <!--<event package="AS" name="AuditAdminOperationsEvent" />-->
					    <event package="AS" name="AuditLogin" />
					    <!--<event package="AS" name="AuditLogout" />-->
					    <!--<event package="AS" name="AuditObjectPermissionEvent" />-->
					    <!--<event package="AS" name="AuditServerStartsAndStops" />-->

					    <!-- ### SESSION EVENTS ### -->
					    <!--<event package="AS" name="ExistingConnection" />-->
					    <!--<event package="AS" name="ExistingSession" />-->
					    <!--<event package="AS" name="SessionInitialize" />-->


					    <target package="Package0" name="event_file">
						    <!-- See: https://msdn.microsoft.com/en-us/library/ff878115(v=sql.120).aspx -->
						    <parameter name="filename" value="$exEventDir\CogitoASTrace.xel" />
						    <parameter name = "max_File_size" value = "5" />
						    <!-- Max size of the file in in MB -->
						    <parameter name = "max_rollover_files" value ="180" />
					    </target>
				    </event_session>
			    </ddl300_300:XEvent>
		    </Trace>
	    </ObjectDefinition>
    </Create>
"@
}
if($TraceType -eq "CogitoASTrace_Verbose"){
        $traceQuery = @"
    <Create
    xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2"
    xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2"
    xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100"
    xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200"
    xmlns:ddl300_300="http://schemas.microsoft.com/analysisservices/2011/engine/300/300">
	    <ObjectDefinition>
		    <Trace>
			    <ID>CogitoASTrace</ID>
			    <Name>CogitoASTrace</Name>
			    <ddl300_300:XEvent>
				    <event_session name="CogitoASTrace" dispatchLatency="1" maxEventSize="4" maxMemory="4"
				     memoryPartitionMode="none" eventRetentionMode="allowSingleEventLoss"
				     trackCausality="true">
					    <!-- ### COMMAND EVENTS ### -->
					    <!--<event package="AS" name="CommandBegin" />-->
					    <event package="AS" name="CommandEnd" />

					    <!-- ### DISCOVER EVENTS ### -->
					    <!--<event package="AS" name="DiscoverBegin" />-->
					    <!--<event package="AS" name="DiscoverEnd" />-->

					    <!-- ### DISCOVER SERVER STATE EVENTS ### -->
					    <!--<event package="AS" name="ServerStateDiscoverBegin" />-->
					    <!--<event package="AS" name="ServerStateDiscoverEnd" />-->

					    <!-- ### ERRORS AND WARNING ### -->
					    <event package="AS" name="Error" />

					    <!-- ### FILE LOAD AND SAVE ### -->
					    <!--<event package="AS" name="FileLoadBegin" />-->
					    <!--<event package="AS" name="FileLoadEnd" />-->
					    <!--<event package="AS" name="FileSaveBegin" />-->
					    <!--<event package="AS" name="FileSaveEnd" />-->
					    <!--<event package="AS" name="PageInBegin" />-->
					    <!--<event package="AS" name="PageInEnd" />-->
					    <!--<event package="AS" name="PageOutBegin" />-->
					    <!--<event package="AS" name="PageOutEnd" />-->

					    <!-- ### LOCKS ### -->
					    <event package="AS" name="Deadlock" />
					    <event package="AS" name="LockAcquired" />
					    <event package="AS" name="LockReleased" />
					    <event package="AS" name="LockTimeout" />
					    <!--<event package="AS" name="LockWaiting" />-->

					    <!-- ### NOTIFICATION EVENTS ### -->
					    <!--<event package="AS" name="Notification" />-->
					    <!--<event package="AS" name="UserDefined" />-->

					    <!-- ### PROGRESS REPORTS ### -->
					    <!--<event package="AS" name="ProgressReportBegin" />-->
					    <!--<event package="AS" name="ProgressReportCurrent" />-->
					    <event package="AS" name="ProgressReportEnd" />
					    <event package="AS" name="ProgressReportError" />

					    <!-- ### QUERY EVENTS ### -->
					    <!--<event package="AS" name="QueryBegin" />-->
					    <event package="AS" name="QueryEnd" />

					    <!-- ### QUERY PROCESSING ### -->
					    <!--<event package="AS" name="CalculateNonEmptyBegin" />-->
					    <!--<event package="AS" name="CalculateNonEmptyCurrent" />-->
					    <!--<event package="AS" name="CalculateNonEmptyEnd" />-->
					    <!--<event package="AS" name="CalculationEvaluation" />-->
					    <!--<event package="AS" name="CalculationEvaluationDetailedInformation" />-->
					    <!--<event package="AS" name="DaxQueryPlan" />-->
					    <!--<event package="AS" name="DirectQueryBegin" />-->
					    <!--<event package="AS" name="DirectQueryEnd" />-->
					    <!--<event package="AS" name="ExecuteMDXScriptBegin" />-->
					    <!--<event package="AS" name="ExecuteMDXScriptCurrent" />-->
					    <!--<event package="AS" name="ExecuteMDXScriptEnd" />-->
					    <event package="AS" name="GetDataFromAggregation" />
					    <event package="AS" name="GetDataFromCache" />
					    <!--<event package="AS" name="QueryCubeBegin" />-->
					    <!--<event package="AS" name="QueryCubeEnd" />-->
					    <!--<event package="AS" name="QueryDimension" />-->
					    <!--<event package="AS" name="QuerySubcube" />-->
					    <!--<event package="AS" name="ResourceUsage" />-->
					    <!--<event package="AS" name="QuerySubcubeVerbose" />-->
					    <!--<event package="AS" name="SerializeResultsBegin" />-->
					    <!--<event package="AS" name="SerializeResultsCurrent" />-->
					    <!--<event package="AS" name="SerializeResultsEnd" />-->
					    <!--<event package="AS" name="VertiPaqSEQueryBegin" />-->
					    <!--<event package="AS" name="VertiPaqSEQueryCacheMatch" />-->
					    <!--<event package="AS" name="VertiPaqSEQueryEnd" />-->

					    <!-- ### SECURITY AUDIT ### -->
					    <!--<event package="AS" name="AuditAdminOperationsEvent" />-->
					    <event package="AS" name="AuditLogin" />
					    <!--<event package="AS" name="AuditLogout" />-->
					    <!--<event package="AS" name="AuditObjectPermissionEvent" />-->
					    <!--<event package="AS" name="AuditServerStartsAndStops" />-->

					    <!-- ### SESSION EVENTS ### -->
					    <!--<event package="AS" name="ExistingConnection" />-->
					    <!--<event package="AS" name="ExistingSession" />-->
					    <!--<event package="AS" name="SessionInitialize" />-->


					    <target package="Package0" name="event_file">
						    <!-- See: https://msdn.microsoft.com/en-us/library/ff878115(v=sql.120).aspx -->
						    <parameter name="filename" value="$exEventDir\CogitoASTrace.xel" />
						    <parameter name = "max_File_size" value = "5" />
						    <!-- Max size of the file in in MB -->
						    <parameter name = "max_rollover_files" value ="180" />
					    </target>
				    </event_session>
			    </ddl300_300:XEvent>
		    </Trace>
	    </ObjectDefinition>
    </Create>
"@
}

if ($logLevel -eq "Debug"){
    $traceQuery
}
<# If not running start trace #>
$response = Invoke-ASCmd -Query $traceQuery -Server $instanceName

if ($response -like '*ErrorCode=*'){
    Write-Log $response Warning
    if ($response -like '*ErrorCode="-1053097982"*'){
        Write-Log "The trace could not be started because the extended event directory could not be found. Common causes are that the instance directory in the extended events directory does not exist. See previous warnings for more information" Error
    }
    else{
        Write-Log "There was an error. See the previous warning for more information." Error
    }
}
else{
    Write-Log $response Debug
}
}Export-ModuleMember -Function Start-SSASXEventTrace
function Get-SSASServerStatus{
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string] $XEventTraceName = "CogitoASTrace"
,[switch] $AttemptToRestartTrace = $true)


Import-Module FC_Log

$clarityServer = ""
$clarityDatabase = ""


Try{
    Add-Type -Path "C:\Program Files\Microsoft.NET\ADOMD.NET\110\Microsoft.AnalysisServices.AdomdClient.dll"
}
Catch{
    Write-Log "There was an error loading 'C:\Program Files\Microsoft.NET\ADOMD.NET\110\Microsoft.AnalysisServices.AdomdClient.dll', try installing the 
Microsoft® SQL Server® 2012 Analysis Management Objects from https://www.microsoft.com/en-us/download/confirmation.aspx?id=29065" Error -ErrorAction Stop
}


$sql = "SELECT InstanceName from Cube.MetaData_Databases group by InstanceName"


Write-Log "SQL used to pull the databases deployed on the server: $sql" Debug
$dbs = Invoke-Sqlcmd $sql -ServerInstance $clarityServer -Database $clarityDatabase -ConnectionTimeout 30



foreach($db in $dbs){

    $conn = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection;
    $conn.ConnectionString = "Data Source=$($db.InstanceName);SspropInitAppName=PowerShell SsasDiscoverCurrentProcesses;"
    Write-Log "Connection string set to: $($conn.ConnectionString)" Debug
    $conn.Open();
    $cmd = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdCommand;
    $cmd.Connection = $conn;
    $dbHasTrace = 0

    $sql = "select count(*) 'NumOfProcessErrors' from tab.SSASExtendedEvents ee 
where Datediff(HOUR,StartDateKey,getdate()) <= 24
and ee.EventClassName = 'Progress Report Error'
and ee.EventInstanceName = '$($db.InstanceName)'
"
Write-Log "SQL used to pull the databases deployed on the server: $sql" Debug
$processingErrorCount = Invoke-Sqlcmd $sql -ServerInstance $clarityServer -Database $clarityDatabase -ConnectionTimeout 30

 $sql = "select count(*) 'NumOfErrors' from tab.SSASExtendedEvents ee 
where Datediff(HOUR,StartDateKey,getdate()) <= 24
and ee.EventClassName = 'Error'
and ee.EventInstanceName = '$($db.InstanceName)'
"
Write-Log "SQL used to pull the databases deployed on the server: $sql" Debug
$ErrorCount = Invoke-Sqlcmd $sql -ServerInstance $clarityServer -Database $clarityDatabase -ConnectionTimeout 30

 $sql = "select count(*) 'NumOfQueries' from tab.SSASExtendedEvents ee 
where Datediff(HOUR,StartDateKey,getdate()) <= 24
and ee.EventClassName = 'Query End'
and ee.EventInstanceName = '$($db.InstanceName)'
"
Write-Log "SQL used to pull the databases deployed on the server: $sql" Debug
$QueryCount = Invoke-Sqlcmd $sql -ServerInstance $clarityServer -Database $clarityDatabase -ConnectionTimeout 30


            $da = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter;
            $mdx = 'select * from $System.Discover_Traces'
            Write-Log "MDX to execute: $mdx" Debug
            $cmd.CommandText = $mdx;
            $da.SelectCommand = $cmd;
            $destDataSet = New-Object System.Data.DataTable;
                $da.Fill($destDataSet) | Out-Null


            foreach ($row in $destDataSet){
                if ($row.TraceID -eq $XEventTraceName){
                    $dbHasTrace += 1
                }
            }

            $emailBody = $emailBody + "<b><u>$($db.InstanceName)</b></u><br>"
            if ($dbHasTrace -eq 0){
                if ($AttemptToRestartTrace){
                    $restartTraceResult = 0
                    Start-SSASXEventTrace -instanceName $($db.InstanceName)
                    $da = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter;
                    $mdx = 'select * from $System.Discover_Traces'
                    Write-Log "MDX to execute: $mdx" Debug
                    $cmd.CommandText = $mdx;
                    $da.SelectCommand = $cmd;
                    $destDataSet = New-Object System.Data.DataTable;
                        $da.Fill($destDataSet) | Out-Null


                    foreach ($row in $destDataSet){
                        if ($row.TraceID -eq $XEventTraceName){
                            $restartTraceResult += 1
                        }
                    }
                    if ($restartTraceResult -ne 0){
                        $emailBody = $emailBody + 
                        "     <font color=orange>ExtendedEvent was not running, but now is. I was able to restart the trace.<font color=black><br>"
                    }
                    else{
                        $emailBody = $emailBody + 
                        "     <font color=red>ExtendedEvent NOT running. Tried to restart the trace and failed.<font color=black><br>"
                    }
                }
                else{
                    $emailBody = $emailBody + 
                    "     <font color=red>ExtendedEvent NOT running.<font color=black><br>"
                }
            }
            else{
                $emailBody = $emailBody + 
                "     <font color=black>ExtendedEvent trace running<br>"
            }
                $emailBody = $emailBody +
                "     Processing Error count in last 24 hours: $($processingErrorCount.NumOfProcessErrors)<br>
                      Error count in last 24 hours: $($ErrorCount.NumOfErrors)<br>
                      Query count in last 24 hours: $($QueryCount.NumOfQueries)<br>
                    <br>"
            }

            $emailBody = $emailBody + " Checkout the Cube hardware utilization <a href=""http://epwcogwkst03:5601/app/kibana#/dashboard/1c02ed20-5dbf-11e7-a915-dd8d61e55d99?_g=(refreshInterval%3A('%24%24hashKey'%3A'object%3A1695'%2Cdisplay%3A'30%20seconds'%2Cpause%3A!f%2Csection%3A1%2Cvalue%3A30000)%2Ctime%3A(from%3Anow-7d%2Cmode%3Aquick%2Cto%3Anow))"">here </a><br>
            Checkout the excel file that surfaces the Extended Event tabular model <a href=""file:///T:\Epic%20Program\Reporting%20Team\Tabular%20Powerpivot%20Models\Extended%20Events%20Viewer.xlsx"">here</a>
            "

Send-MailMessage -To "" -from "" -Subject "SSAS Instance Health" -Body $emailBody -BodyAsHtml -SmtpServer "dhsmtpinternal"

}Export-ModuleMember -Function Get-SSASServerStatus
function Get-Type { 
    param($type) 
 
$types = @( 
'System.Boolean', 
'System.Byte[]', 
'System.Byte', 
'System.Char', 
'System.Datetime', 
'System.Decimal', 
'System.Double', 
'System.Guid', 
'System.Int16', 
'System.Int32', 
'System.Int64', 
'System.Single', 
'System.UInt16', 
'System.UInt32', 
'System.UInt64') 
 
    if ( $types -contains $type ) { 
        Write-Output "$type" 
    } 
    else { 
        Write-Output 'System.String' 
         
    } 
} 
function Out-DataTable { 
<# 
.SYNOPSIS 
Creates a DataTable for an object 
.DESCRIPTION 
Creates a DataTable based on an objects properties. 
.INPUTS 
Object 
    Any object can be piped to Out-DataTable 
.OUTPUTS 
   System.Data.DataTable 
.EXAMPLE 
$dt = Get-psdrive| Out-DataTable 
This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable 
.NOTES 
Adapted from script by Marc van Orsouw see link 
Version History 
v1.0  - Chad Miller - Initial Release 
v1.1  - Chad Miller - Fixed Issue with Properties 
v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0 
v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties 
v1.4  - Chad Miller - Corrected issue with DBNull 
v1.5  - Chad Miller - Updated example 
v1.6  - Chad Miller - Added column datatype logic with default to string 
v1.7 - Chad Miller - Fixed issue with IsArray 
.LINK 
http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx 
#> 
    [CmdletBinding()] 
    param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject) 
 
    Begin 
    { 
        $dt = new-object Data.datatable   
        $First = $true  
    } 
    Process 
    { 
        foreach ($object in $InputObject) 
        { 
            $DR = $DT.NewRow()   
            foreach($property in $object.PsObject.get_properties()) 
            {   
                if ($first) 
                {   
                    $Col =  new-object Data.DataColumn   
                    $Col.ColumnName = $property.Name.ToString()   
                    if ($property.value) 
                    { 
                        if ($property.value -isnot [System.DBNull]) { 
                            $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)") 
                         } 
                    } 
                    $DT.Columns.Add($Col) 
                }   
                if ($property.Gettype().IsArray) { 
                    $DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1 
                }   
               else { 
                    $DR.Item($property.Name) = $property.value 
                } 
            }   
            $DT.Rows.Add($DR)   
            $First = $false 
        } 
    }  
      
    End 
    { 
        Write-Output @(,($dt)) 
    } 
 
} Export-ModuleMember -Function Out-DataTable
function Write-DataTable { 
<# 
.SYNOPSIS 
Writes data only to SQL Server tables. 
.DESCRIPTION 
Writes data only to SQL Server tables. However, the data source is not limited to SQL Server; any data source can be used, as long as the data can be loaded to a DataTable instance or read with a IDataReader instance. 
.INPUTS 
None 
    You cannot pipe objects to Write-DataTable 
.OUTPUTS 
None 
    Produces no output 
.EXAMPLE 
$dt = Invoke-Sqlcmd2 -ServerInstance "Z003\R2" -Database pubs "select *  from authors" 
Write-DataTable -ServerInstance "Z003\R2" -Database pubscopy -TableName authors -Data $dt 
This example loads a variable dt of type DataTable from query and write the datatable to another database 
.NOTES 
Write-DataTable uses the SqlBulkCopy class see links for additional information on this class. 
Version History 
v1.0   - Chad Miller - Initial release 
v1.1   - Chad Miller - Fixed error message 
.LINK 
http://msdn.microsoft.com/en-us/library/30c3y597%28v=VS.90%29.aspx 
https://gallery.technet.microsoft.com/ScriptCenter/2fdeaf8d-b164-411c-9483-99413d6053ae/
#>
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$true)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$true)] [string]$TableName, 
    [Parameter(Position=3, Mandatory=$true)] $Data, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=5, Mandatory=$false)] [string]$Password, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$BatchSize=50000, 
    [Parameter(Position=7, Mandatory=$false)] [Int32]$QueryTimeout=0, 
    [Parameter(Position=8, Mandatory=$false)] [Int32]$ConnectionTimeout=15 
    ) 
     
    $conn=new-object System.Data.SqlClient.SQLConnection 
 
    if ($Username) 
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
    else 
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
 
    $conn.ConnectionString=$ConnectionString 
 
    try 
    { 
        $conn.Open() 
        $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString 
        $bulkCopy.DestinationTableName = $tableName 
        $bulkCopy.BatchSize = $BatchSize 
        $bulkCopy.BulkCopyTimeout = $QueryTimeOut 
        $bulkCopy.WriteToServer($Data) 
        $conn.Close() 
    } 
    catch 
    { 
        $ex = $_.Exception 
        Write-Error "$ex.Message" 
        continue 
    } 
 
} Export-ModuleMember -Function Write-DataTable
function Import-FlatFileToSQLServer{
<#
    .Synopsis
      Loads data from TXT files generated by Trauma1 into sql tables by creating a generic STAGE table with varchar(max) column data types, and then loading the flat file contents into it.  
    .DESCRIPTION
      A slightly longer description,
    .PARAMETER inputDir
        The directory to pull files from, or the path to a single file to import. 
    .PARAMETER extensionsToInclude
        An array of file types to import. 

        IE: @(".TXT",".CSV")
    .PARAMETER destServerName
        The server name that this will execute against. 
    .PARAMETER destDatabase
        The database name that this will execute against. You need to have access to create and insert data in this database. 

    .PARAMETER schemaName
        The schema name the new tables will have. If the this schema name does not exist, it will create a new one. 
    .PARAMETER executeScripts
        When this switch is activated, the create schema and create table SQL scripts will be executed against the target server/database

    .PARAMETER loadData
         When this switch is activated, the data from the flat files are loaded into tables that match the file name. 
      
    .PARAMETER delimiter
        The character that is deliminating columns in the flat file. Defaults to a comma ","

    .PARAMETER tempDir
        The temp directory to use to store the sql files that are generated. defaults to $env:TEMP
#>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info"
,[switch] $winEventLog
,[string] $inputDir = $null
,[string[]] $extensionsToInclude = @()
,[string] $tempDir = $env:TEMP
,[string] $destServerName = $null
,[string] $destDatabase = $null
,[string] $schemaName = $null
,[switch] $executeScripts
,[switch] $loadData
,[string] $delimiter = ",")

    import-module FC_Log, DataAccess -Force -DisableNameChecking
    if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
    Set-LogLevel $logLevel
    Set-logTargetWinEvent $winEventLog

    Write-Log "Begining to load data from files with an extension of: ($extensionsToInclude) 
    From the directory: $inputDir" 
    Write-Log ""

    if (!(Test-Path $inputDir)){
        Write-Log "Error finding the path: $inputDir" Error -ErrorAction Stop
    }
    if ((Get-ChildItem $inputDir) -is [System.IO.Fileinfo]){
        $files = Get-ChildItem -Path $inputDir | where Extension -in $extensionsToInclude
    }
    else{
        $files = Get-ChildItem -Path $inputDir | where Extension -in $extensionsToInclude
    }

    if ($files -eq $null){
        Write-Log "Could not find any files with an extension of: $extensionsToInclude at the path: $inputDir. Aborting" Error -ErrorAction Stop
    }
    $loadDate = "$([DateTime]::Now.Year).$([DateTime]::Now.Month).$([DateTime]::Now.Day) "

    $SQLCreateTableStatements = @()

    $sqlCreateSchema = "USE [$destDatabase]
    Go

    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = '$schemaName')
        exec('CREATE SCHEMA [$schemaName];')
            "
            $createSchemaSQLFile = "$tempDir\Trauma1CreateSchema_$schemaName.sql"
            if (Test-Path $createSchemaSQLFile){
                Remove-Item $createSchemaSQLFile
            }
            $sqlCreateSchema | Add-Content $createSchemaSQLFile

    if ($executeScripts){
        Invoke-Sqlcmd -ServerInstance $destServerName -Database $destDatabase -Query $sqlCreateSchema -ErrorAction Stop
    }

    $objStore = @()

    foreach($file in $files){
        try{
            $inputFilePath = $file.fullname
        
            $myObj = New-Object psobject
            $myObj | Add-Member -MemberType NoteProperty -Name FilePath -Value $inputFilePath
            $myObj | Add-Member -MemberType NoteProperty -Name ErrorExists -Value 0
            $myObj | Add-Member -MemberType NoteProperty -Name sqlCommand -Value ""
            $myObj | Add-Member -MemberType NoteProperty -Name ErrorValue -Value ""

            Write-Log "Loading the file: $inputFilePath" Debug
            $tableName = "Stage_$($file.Name)"
            $FQTableName = "[$schemaName].[$tableName]"
            $data = Import-Csv $inputFilePath -Delimiter $delimiter
            $dataAsDataTable = $data | Out-DataTable
            $colNames = (Get-Content $inputFilePath | Select-Object -First 1).Split($delimiter)
            $SQLCreateTable = "USE [$destDatabase]
    Go
    "

            $SQLCreateTable += "
    IF OBJECT_ID('[$destDatabase].$FQTableName') is not null
        Drop Table $FQTableName;

    "

        
            $SQLCreateTable += "
    Create table $FQTableName (
        "
            $firstPass = 1
            foreach ($col in $colNames){
                if ($firstPass -eq 1){
                    $SQLCreateTable = $SQLCreateTable + "[$col] varchar(max) null"
                    $firstPass = 0
                }
                else{
                    $SQLCreateTable = $SQLCreateTable + ",[$col] varchar(max) null"
                }
            }
            $SQLCreateTable = $SQLCreateTable + "
            );

        "
            $myObj.sqlCommand = $SQLCreateTable

            $createTableSQLFile = "$tempDir\Trauma1CreateTable_$tableName.sql"
            if (Test-Path $createTableSQLFile){
                Remove-Item $createTableSQLFile
            }
            $SQLCreateTable | Add-Content $createTableSQLFile

            if ($executeScripts){
                Write-Log "Executing create table script for $FQTableName"
                Invoke-Sqlcmd -ServerInstance $destServerName -Database $destDatabase -Query $SQLCreateTable -ErrorAction Stop
            }

            if ($loadData){
                Write-Log "Loading data into $FQTableName" -tabLevel 1
                Write-DataTable -serverInstance $destServerName -Database $destDatabase -TableName $FQTableName -data $dataAsDataTable
                }
        }
        catch{
            $myObj.ErrorExists = 1
            $myObj.ErrorValue = $_
        }

        $objStore += $myObj
   
    }


    Write-Log "Completed reading files."

    $errorCount = ($objStore | where ErrorExists -eq 1).Count

    if ($errorCount -ne 0){
        Write-Log "There were $errorCount files that did not load" Warning
        foreach ($obj in $objStore | where ErrorExists -eq 1){
            Write-Log "$($obj.FilePath)" -tabLevel 1
            Write-Log "$($obj.ErrorValue)" -tablevel 2
        }
    } 
} Export-ModuleMember -Function Import-FlatFileToSQLServer
function Invoke-SqlAgentJobSync{
<#
    .Synopsis
      Executes a SQL server agent job
    #>
param (
 [string] $instancename = $null,
 [string] $jobname = $null
)

$db = "MSDB"
$sqlConnection = new-object System.Data.SqlClient.SqlConnection 
$sqlConnection.ConnectionString = 'server=' + $instancename + ';integrated security=TRUE;database=' + $db 
$sqlConnection.Open() 
$sqlCommand = new-object System.Data.SqlClient.SqlCommand 
$sqlCommand.CommandTimeout = 120 
$sqlCommand.Connection = $sqlConnection 
$sqlQuery = "exec dbo.sp_start_job $jobname"
Write-Log "sqlQuery: $sqlQuery" Debug
$sqlCommand.CommandText= $sqlQuery
Write-Host "Executing Job => $jobname..." 
$result = $sqlCommand.ExecuteNonQuery() 
$sqlConnection.Close()
} Export-ModuleMember -Function Invoke-SqlAgentJobSynch