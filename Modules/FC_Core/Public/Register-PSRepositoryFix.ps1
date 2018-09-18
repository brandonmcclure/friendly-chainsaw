function Register-PSRepositoryFix {
<#
    .Synopsis
      This function is used as a workaround for an apparent bug when registering a PSRepository that uses an SSL endpoint. See https://stackoverflow.com/questions/35296482/invalid-web-uri-error-on-register-psrepository/35296483
    .LINK
       Source - https://stackoverflow.com/questions/35296482/invalid-web-uri-error-on-register-psrepository/35296483
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $Name,

    [Parameter(Mandatory = $true)]
    [uri]
    $SourceLocation,

    [ValidateSet('Trusted','Untrusted')]
    $InstallationPolicy = 'Trusted'
  )

  $ErrorActionPreference = 'Stop'

  try {
    Write-Verbose 'Trying to register via ​Register-PSRepository'
    ​Register-PSRepository -Name $Name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy
    Write-Verbose 'Registered via Register-PSRepository'
  } catch {
    Write-Verbose 'Register-PSRepository failed, registering via workaround'

    # Adding PSRepository directly to file
    Register-PSRepository -Name $Name -SourceLocation $env:TEMP -InstallationPolicy $InstallationPolicy
    $PSRepositoriesXmlPath = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet\PSRepositories.xml"
    $repos = Import-Clixml -Path $PSRepositoriesXmlPath
    $repos[$Name].SourceLocation = $SourceLocation.AbsoluteUri
    $repos[$Name].PublishLocation = (New-Object -TypeName Uri -ArgumentList $SourceLocation,'package/').AbsoluteUri
    $repos[$Name].ScriptSourceLocation = ''
    $repos[$Name].ScriptPublishLocation = ''
    $repos | Export-Clixml -Path $PSRepositoriesXmlPath

    # Reloading PSRepository list
    Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    Write-Verbose 'Registered via workaround'
  }
} Export-ModuleMember -Function Register-PSRepositoryFix