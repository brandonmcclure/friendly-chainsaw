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
  param([Parameter(Position = 0,Mandatory = $true,ValueFromPipeline = $true)] [PSObject[]]$InputObject)

  begin
  {
    $dt = New-Object Data.datatable
    $First = $true
  }
  process
  {
    foreach ($object in $InputObject)
    {
      $DR = $DT.NewRow()
      foreach ($property in $object.psobject.get_properties())
      {
        if ($first)
        {
          $Col = New-Object Data.DataColumn
          $Col.ColumnName = $property.Name.ToString()
          if ($property.Value)
          {
            if ($property.Value -isnot [System.DBNull]) {
              $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)")
            }
          }
          $DT.Columns.Add($Col)
        }
        if ($property.GetType().IsArray) {
          $DR.Item($property.Name) = $property.Value | ConvertTo-Xml -As String -NoTypeInformation -Depth 1
        }
        else {
          $DR.Item($property.Name) = $property.Value
        }
      }
      $DT.Rows.Add($DR)
      $First = $false
    }
  }

  end
  {
    Write-Output @(,($dt))
  }

} Export-ModuleMember -Function Out-DataTable