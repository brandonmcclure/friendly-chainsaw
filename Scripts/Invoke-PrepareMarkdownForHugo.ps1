<#
    .Synopsis
      This script is designed to bootstrap my existing Markdown files so that they can be used in Hugo generated sites. It just adds front matter with the title == file basename
    #>
	[CmdletBinding(SupportsShouldProcess=$true)] 
	param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info"
	,[string]$Path = ''
	)
	
	Import-Module FC_Log
	
	if ([string]::IsNullOrEmpty($logLevel)){$logLevel = "Info"}
	Set-LogLevel $logLevel
		
	Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]" Debug
	
	$files = Get-ChildItem -Path $Path -Filter '*.md' -File

	$fileCount = $files | Measure-Object | Select-Object -ExpandProperty Count
    Write-Log "Found $fileCount files"

	foreach($file in $files){
			Write-Log "File: $($file.Name)"
		$cont = Get-Content $file.FullName -First 1

		if($cont -ne '---'){
			Write-Log "Inserting the front matter"
			$frontMatter = '---
title: "'+$file.BaseName+'"
linkTitle: "'+$file.BaseName+'"
type: docs
weight: 5
---
'	
			$tempFilePath = "$env:temp\tempfile.txt"
			$frontMatter | Set-Content $tempFilePath
		Get-Content $file.Fullname -ReadCount 5000 | Add-Content $tempFilePath
   		Remove-item $file.Fullname
   		Move-Item $tempFilePath $file.FullName

		}
	}
	
	Write-Log "$PSCommandPath ended at: [$([DateTime]::Now)]" Debug