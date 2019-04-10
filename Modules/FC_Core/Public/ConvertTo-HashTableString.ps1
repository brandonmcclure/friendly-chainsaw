Function ConvertTo-HashTableString{
<#
    .Synopsis
      Converts a Powershell Object into a string representation of a HashTable
    .DESCRIPTION
      I really like testing my functions, but sometimes it is difficult to figure out exactly how my Mock should be constructed. This function enables me to take a real life instance of a thing, and get a string with a hash table that I can use for my Mock

    .EXAMPLE
    .INPUTS
       One or more PS Object
    .OUTPUTS
       One or more strings
    #>
param([Parameter(ValueFromPipeline)][object[]]$inputObect,
[switch] $MockablePSObject
,[switch] $ComparableHashTable
)
begin{
    $result = new-object PsObject
    $result | add-member -type noteproperty -name "MockablePSObject" -value ""
    $result | add-member -type noteproperty -name "ComparableHashTable" -value ""
}
process{
 $objCount = ($inputObect | Measure-Object).Count
if ($objCount -eq 0){return $null}

$outHash = "@{"



foreach ($item in $inputObect){

foreach ($k in ($inputObect | Get-Member -MemberType NoteProperty).Name) {
    if ($($item.$k).GetType().FullName -eq "System.Management.Automation.PSCustomObject"){
        $x = 0;
        $innerHash ="@{"
        foreach ($y in ($($item.$k) | Get-Member -MemberType NoteProperty).Name){
            $innerHash+="$y = '$($($item.$k.$y).Replace("`'","`'`'"))'"
        }
        $innerhash+="}"
        $outHash+=$innerHash
    }
    else{

    $outHash+= "$k = '$($($item.$k).Replace("`'","`'`'"))'
"
}
    }
    }

    $outHash += "}"
    $outObj = "[PSCustomObject]$outHash"
    if ([string]::IsNullOrEmpty($result.MockablePSObject)){
        $result.MockablePSObject += "$outObj"
    }else{
        $result.MockablePSObject += ",$outObj"
    }
    if ([string]::IsNullOrEmpty($result.ComparableHashTable)){
        $result.ComparableHashTable += "$outHash"
    }else{
        $result.ComparableHashTable += ",$outHash"
    }
    }
    end{

        if ([string]::IsNullOrEmpty($result.MockablePSObject) -and [string]::IsNullOrEmpty($result.ComparableHashTable)){
            Write-Output $null 
            return
        }
        If ($MockablePSObject -and -not $ComparableHashTable){
            Write-Output $result | select -ExpandProperty MockablePSObject
            return
        }
        If ($ComparableHashTable -and -not $MockablePSObject){
            Write-Output $result | select -ExpandProperty ComparableHashTable
            return
        }
        else{
            Write-Output $result
            return
        }
    }
    }Export-ModuleMember -Function ConvertTo-HashTableString