function Compare-JoinedObjectMembers {
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
  param([psobject]$obj,[string]$joinPrefix)
  $leftMembers = $obj | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" -and $_.Name -notlike "$joinPrefix*" } | Select-Object Name
  $rightMembers = $obj | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" -and $_.Name -like "$joinPrefix*" } | Select-Object Name
  $outputValue = @()
  foreach ($member in $leftMembers.Name) {
    Write-Log "Evaluating the $member property for a coredsponding property that named: $joinPrefix$member " Debug
    $found = 0
    foreach ($rightMember in $rightMembers.Name) {
      if ($($rightMember.Replace($joinPrefix,'')) -eq $member) {
        $found = 1
      }
    }
    if ($found -eq 0) {
      $outputValue += $member
    }
  }

  return $outputValue
} Export-ModuleMember -Function Compare-JoinedObjectMembers