function Set-TFSPolicyConfiguration{
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
    
    
    $outputObj = $pipelineInput
    $repositoryID = $pipelineInput.repository.id
    $policyConfigs = $pipelineInput.PolicyConfigurations

    foreach ($policyConfig in $policyConfigs){

        $props = $policyConfig | Get-Member -Type NoteProperty | where {$_.Name -in '_links','createdBy','createdDate','isBlocking','settings','type','isDeleted','isEnabled','revision','url'} | Select -ExpandProperty Name
        $configurationID = $policyConfig.id
        if ([String]::IsNullOrEmpty($repositoryID)){
            Write-Log "Please pass a repositoryID" Error -ErrorAction Stop
        }
        if ([String]::IsNullOrEmpty($configurationID)){
            Write-Log "Please pass a configurationID" Error -ErrorAction Stop
        }
        $BaseTFSURL = Get-TFSRestURL
        $action = "/_apis/policy/configurations/$($configurationID)?api-version=$($script:apiVersion)" 
        $fullURL = $BaseTFSURL + $action
        Write-Log "URL we are calling: $fullURL" Debug
        Write-Log "Updating policy: $($policyCOnfig.Settings.DisplayName) or type: $($policyConfig.Type.DisplayName)"
        $authHeader = ($script:AuthHeader | ConvertFrom-SecureString -AsPlainText | ConvertFrom-Json -Depth 2) | Foreach-Object { $key = $_; [hashtable] @{Authorization = $Key.Authorization}}
        $body = $($policyConfig | select $props) | ConvertTo-Json -Depth 8
        $result = Invoke-WebRequest -Method Put -Body $body -Uri $fullURL -UseDefaultCredentials -Headers $authHeader -ContentType "application/json"

        $x=0;
        
    }

    Write-Output $outputObj
    } Export-ModuleMember -Function Set-TFSPolicyConfiguration