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

  if ($types -contains $type) {
    Write-Output "$type"
  }
  else {
    Write-Output 'System.String'

  }
}