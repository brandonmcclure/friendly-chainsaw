<#
    .Synopsis
      A simple script that I wrote to make catalogging my lego manuals easier
    .DESCRIPTION
		This script will open up N number of browser windows for you to manually download the pdf files from lego's website. 

		It will also output a csv file that can be imported into rebrickable.com

      Check out the related blog post: https://brandonmcclure.gitlab.io/orgmode/2022.02.23-lego-manual-downloads/
    .LINK
       https://brandonmcclure.gitlab.io/orgmode/2022.02.23-lego-manual-downloads/
    #>

	param(
# Enter the path to the web broser you want to use to download the files. I used Firefox, ymmv with other browsers
$browserPath = "C:\Program Files\Mozilla Firefox\firefox.exe",

# A list of the set numbers, the example below is for this set https://www.lego.com/en-us/service/buildinginstructions/75233
$sets = @(
	'75233'
)
	)
$rebrickableOutData =@()
foreach($set in $sets){
	$rebrickableOutData += New-Object PSCustomObject -Property @{
		'set number' = "$set-1";
		quantity = 1
	}

	. $browserPath "https://www.lego.com/en-us/service/buildinginstructions/$set"
}

$rebrickableOutData | Export-Csv -path "$($env:USERPROFILE)\downloads\rebrickable.csv" -NoTypeInformation