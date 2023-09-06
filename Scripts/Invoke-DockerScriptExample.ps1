<#
    .Synopsis
      A simple test script to demonstrate how to call scripts from this docker image
    .PARAMETER name
        Defaults to "No Name"

        Used to change the output of the script
#>
param(
    $name = "No Name"
)
Import-Module FC_Log

Write-Log "Hello $name"