function Get-TFSPolicyTypes{
    <#
        .Synopsis
          Please give your script a brief Synopsis,
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
    [CmdletBinding(SupportsShouldProcess=$true)] 
    param([Parameter(ValueFromPipeline)] $pipelineInput)
    
    
    $outputObj = New-Object PSObject
    $outputObj | Add-Member -Type NoteProperty -Name repository -Value $pipelineInput.Repository
    $repositoryID = $pipelineInput.repository.id
    
    if ([String]::IsNullOrEmpty($repositoryID)){
        Write-Log "Please pass a repositoryID" Error -ErrorAction Stop
    }
    $BaseTFSURL = Get-TFSRestURL
    $action = "/_apis/policy/types?api-version=$($script:apiVersion)" 
    $fullURL = $BaseTFSURL + $action
    Write-Log "URL we are calling: $fullURL" Debug
    $outresponse = (Invoke-RestMethod -UseDefaultCredentials -uri $fullURL -Method Get -ContentType "application/json-patch+json" -Headers $(($script:AuthHeader | ConvertFrom-SecureString -AsPlainText | ConvertFrom-Json -Depth 2) | Foreach-Object { $key = $_; [hashtable] @{Authorization = $Key.Authorization}} )).Value
    
    $outputObj | Add-Member -Type NoteProperty -Name PolicyTypes -Value $outresponse
    Write-Output $outputObj
    } Export-ModuleMember -Function Get-TFSPolicyTypes