function Deploy-ChocolateyPackagesToRepo{
	[CmdletBinding(SupportsShouldProcess=$true)] 
	param([Parameter(position=0)][ValidateSet("Debug","Verbose","Info","Warning","Error", "Disable")][string] $logLevel = "Verbose",
	$source = "MCD_Chocolatey"
	,$directory = 'C:\Users\brandon\Downloads\n')

	if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
		Set-LogLevel $logLevel

	$files = Get-ChildItem -Path $directory -Recurse -Filter '*nupkg'
	Write-Log "Found $(($files | Measure-Object).Count) files"
	foreach ($file in $files){
		try{
			$options = "push -Source $source -ApiKey AzureDevOps `"$($file.FullName)`" -Verbosity Detailed -Timeout 120"
			if ($pscmdlet.ShouldProcess("$($file.name)", "nuget.exe $options")){
				Write-Log "Attempting to push: $($file.Name)"
				$result = Start-MyProcess -EXEPath "nuget.exe" -options $options
				if ($result.stderr -like '*409 (Conflict*'){
					Write-Log "     There was a version conflict, ignoring it"
				}
				elseif ( -not [string]::IsNullOrEmpty($result.stderr)){
					Write-Log "nuget stderr: $($result.stderr)" Warning
				}
				Write-Log "nuget stdout: $($result.stdout)" Verbose
				
				
			}
		}
		catch{
			throw
		}
	}
}