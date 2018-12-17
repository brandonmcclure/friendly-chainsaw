Function ConvertTo-HashTableString{
<#
    .Synopsis
      Converts a Powershell Object into a string representation of a HashTable
    .DESCRIPTION
      I really like testing my functions, but sometimes it is difficult to figure out exactly how my Mock should be constructed. This function enables me to take a real life instance of a thing, and get a string with a hash table that I can use for my Mock

    .INPUTS
       One or more PS Object
    .OUTPUTS
       One or more strings
    #>
param([Parameter(ValueFromPipeline)][object[]]$inputObect)

process{
$objCount = ($inputObect | Measure-Object).Count
if ($objCount -eq 0){return $null}
$outHash = "@{"

foreach ($item in $inputObect){

foreach ($k in ($inputObect | Get-Member -MemberType NoteProperty).Name) {
    $outHash+= "$k = '$($item.$k)'
"
    }
    }

    $outHash += "}"

    Write-Output "$outHash"
    }
    }Export-ModuleMember -Function ConvertTo-HashTableString