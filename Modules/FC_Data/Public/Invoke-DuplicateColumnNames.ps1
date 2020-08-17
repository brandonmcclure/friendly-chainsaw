function Invoke-DuplicateColumnNames
{
<# 
.SYNOPSIS 
    Takes an array of column names (like from a flat file) and will automatically add a counter to any duplicates.

    With the array ("ColA","ColB","ColA") it will output a array: ("ColA_1",ColB","ColA_02")
.DESCRIPTION
    
.INPUTS 
     Array of stirngs

.OUTPUTS 
   Array of strings

.PARAMETER
    colNames
        An string array of column names
.EXAMPLE 


#>
param(
[string[]]$colNames )
    $counter = 1;
    for($i=0;$i-le $colNames.Count;$i++){
        foreach($r in $colNames){
            if ($colNames[$i] -eq $r -and [array]::indexof($colNames,$r) -ne $i){
                $colNames[$i] = "$($colNames[$i])_$counter"
                $counter++;
            }
        }
    }

    Write-Output $colNames
} Export-ModuleMember -function Invoke-DuplicateColumnNames