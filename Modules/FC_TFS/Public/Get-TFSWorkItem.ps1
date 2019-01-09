Function Get-TFSWorkItem{
<#
    .Synopsis
      Please give your script a brief Synopsis,
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
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(ValueFromPipeline)] $pipelineInput
,[int] $WorkItemID)

$repositoryID = $pipelineInput.repository.id
function ConvertFrom-Json2{
<#
	.SYNOPSIS
		The ConvertFrom-Json cmdlet converts a JSON-formatted string to a custom object (PSCustomObject) that has a property for each field in the JSON 

	.DESCRIPTION
		The ConvertFrom-Json cmdlet converts a JSON-formatted string to a custom object (PSCustomObject) that has a property for each field in the JSON 

	.PARAMETER InputObject
		Specifies the JSON strings to convert to JSON objects. Enter a variable that contains the string, or type a command or expression that gets the string. You can also pipe a string to ConvertFrom-Json.
	
	.PARAMETER MaxJsonLength
		Specifies the MaxJsonLength, can be used to extend the size of strings that are converted.  This is the main feature of this cmdlet vs the native ConvertFrom-Json2

	.EXAMPLE
		Get-Date | Select-Object -Property * | ConvertTo-Json | ConvertFrom-Json
	
		DisplayHint : 2
	
		DateTime    : Friday, January 13, 2012 8:06:31 PM
	
		Date        : 1/13/2012 8:00:00 AM
	
		Day         : 13
	
		DayOfWeek   : 5
	
		DayOfYear   : 13
	
		Hour        : 20
	
		Kind        : 2
	
		Millisecond : 400
	
		Minute      : 6
	
		Month       : 1
	
		Second      : 31
	
		Ticks       : 634620819914009002
	
		TimeOfDay   : @{Ticks=723914009002; Days=0; Hours=20; Milliseconds=400; Minutes=6; Seconds=31; TotalDays=0.83786343634490734; TotalHours=20.108722472277776; TotalMilliseconds=72391400.900200009; TotalMinutes=1206.5233483366667;TotalSeconds=72391.4009002}
	
		Year        : 2012
	
		This command uses the ConvertTo-Json and ConvertFrom-Json cmdlets to convert a DateTime object from the Get-Date cmdlet to a JSON object.

		The command uses the Select-Object cmdlet to get all of the properties of the DateTime object. It uses the ConvertTo-Json cmdlet to convert the DateTime object to a JSON-formatted string and the ConvertFrom-Json cmdlet to convert the JSON-formatted string to a JSON object..
	
	.EXAMPLE
		PS C:\>$j = Invoke-WebRequest -Uri http://search.twitter.com/search.json?q=PowerShell | ConvertFrom-Json
	
		This command uses the Invoke-WebRequest cmdlet to get JSON strings from a web service and then it uses the ConvertFrom-Json cmdlet to convert JSON content to objects that can be  managed in Windows PowerShell.

		You can also use the Invoke-RestMethod cmdlet, which automatically converts JSON content to objects.
		Example 3
		PS C:\>(Get-Content JsonFile.JSON) -join "`n" | ConvertFrom-Json
	
		This example shows how to use the ConvertFrom-Json cmdlet to convert a JSON file to a Windows PowerShell custom object.

		The command uses Get-Content cmdlet to get the strings in a JSON file. It uses the Join operator to join the strings in the file into a single string that is delimited by newline characters (`n). Then it uses the pipeline operator to send the delimited string to the ConvertFrom-Json cmdlet, which converts it to a custom object.

		The Join operator is required, because the ConvertFrom-Json cmdlet expects a single string.

	.NOTES
		Author: Reddit
		Version History:
			1.0 - Initial release
		Known Issues:
			1.0 - Does not convert nested objects to psobjects
	.LINK
#>

[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]

param
(  
	[parameter(
		ParameterSetName='object',
		ValueFromPipeline=$true,
		Mandatory=$true)]
		[string]
		$InputObject,
	[parameter(
		ParameterSetName='object',
		ValueFromPipeline=$true,
		Mandatory=$false)]
		[int]
		$MaxJsonLength = 67108864

)#end param

BEGIN 
{ 
	
	#Configure json deserializer to handle larger then average json conversion
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.Web.Extensions')        
	$jsonserial= New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer 
	$jsonserial.MaxJsonLength  = $MaxJsonLength

} #End BEGIN

PROCESS
{
	if ($PSCmdlet.ParameterSetName -eq 'object')
	{
		$deserializedJson = $jsonserial.DeserializeObject($InputObject)

		# Convert resulting dictionary objects to psobjects
		foreach($desJsonObj in $deserializedJson){
			$psObject = New-Object -TypeName psobject -Property $desJsonObj

			$dicMembers = $psObject | Get-Member -MemberType NoteProperty
            
            foreach ($member in $dicMembers){
                $member.GetType()
                if ($member -is [System.Collections.Generic.Dictionary`2])
                {
                    $psObject.$member = New-Object -TypeName psobject -Property $psObject.$member
                    $a = 0;
                }
                $x = 0;
            }
			# Need to recursively go through members of the originating psobject that have a .GetType() Name of 'Dictionary`2' 
			# and convert to psobjects and replace the current member in the $psObject tree

			$psObject
		}
	}


}#end PROCESS

END
{
}#end END

}
if ([String]::IsNullOrEmpty($repositoryID)){
    Write-Log "Please pass a repositoryID" Error -ErrorAction Stop
}
$BaseTFSURL = Get-TFSRestURL_Collection
$action = "/wit/workitems/$($workItemID)?api-version=$($script:apiVersion)" 
$fullURL = $BaseTFSURL + $action
Write-Log "URL we are calling: $fullURL" Debug
$outputObj = $pipelineInput

try{
$response = Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json"
$json = $response
$x = 0;
}
catch{
    $ex = $_.Exception
    if ($ex.response -ne $null){
    $errResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errResponse) 
     $reader.BaseStream.Position = 0 
     $reader.DiscardBufferedData() 
     $responseBody = $reader.ReadToEnd(); 
     $responseBody 
     }

    $line = $_.InvocationInfo.ScriptLineNumber
    $scriptName = Split-Path $_.InvocationInfo.ScriptName -Leaf
    $msg = $ex.Message
    Write-Log "Error in script $scriptName at line $line, error message: $msg" Warning
}
if([bool]($outputObj.PSobject.Properties.name -match "WorkItems")){
    $outputObj.WorkItems += $json
}
else{
    $outputObj | Add-Member -Type NoteProperty -Name WorkItems -Value $json
}
Write-Output $outputObj

}Export-ModuleMember -Function Get-TFSWorkItem