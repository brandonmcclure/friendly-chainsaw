function Invoke-DockerImageBuild{
    param(
    $registry
    ,$repository
    ,[bool]$isLatest
    ,$workingDir
    ,$imageName
    ,$buildArgs = @{}
    ,$customTags = @()
    ,$tagPrefix
    ,$logLevel
    ,[switch] $gitTag
    )
    
    if($null -eq $registry){
        if ($null -ne [Environment]::GetEnvironmentVariable("DOCKER_REGISTRY", "User")){
            Write-Host "Using the USER DOCKER_REGISTRY variable"
            $registry = [Environment]::GetEnvironmentVariable("DOCKER_REGISTRY", "User")
        }
        if($null -eq $registry){
            $registry = ""
        }
    }
    
    $buildargString = ""
    foreach ($a in $buildArgs.Keys){
        $buildargString += " --build-arg $($a)=$($buildArgs.$a)"
    }
        $buildargString = $buildargString.TrimStart(' ')
    
        $oldLocation = Get-Location
        Set-Location $workingDir
        $tags = @()
        if($gitTag){
        try{
            $tags += "$((Get-GitStatus | select -ExpandProperty Branch) -replace "/","_")-$((Get-GitLastCommit).SubString(0,4))"
        }
        catch{
            Write-Warning "Could not Get-GitStatus or Get-GitLastCommit"
        }
    }
        if($isLatest){
            $tags += 'latest'
        }
    
        foreach ($tag in $customTags){
            $tags += $tag
        }

        $legitTags = @()
        if (-not[string]::IsNullOrEmpty($tagPrefix)){
            foreach ($t in $tags){
                $legitTags += "$tagPrefix$t"
            }
        }
        else{
            $legitTags = $tags
        }
        
    
        foreach($tag in $legitTags){
            Write-Log "FQ Image Parts" Debug
            Write-Log "registry: $($registry.TrimEnd('\'))" Debug
            Write-Log "repository: $repository" Debug
            Write-Log "imageName: $($imageName.ToLower())" Debug
            Write-Log "tag: $($tag.ToLower())" Debug
    
            $FQImageName = "$(if([string]::IsNullOrEmpty($registry)){''}elseif($registry.EndsWith("/")){$registry}else{$registry+"/"})$(if([string]::IsNullOrEmpty($repository)){''}elseif($repository.EndsWith("/")){$repository}else{$repository+"/"})$($imageName.ToLower()):$($tag.ToLower())"
            Write-Log "FQImageName: $FQImageName" Debug
            Write-Log "buildargString: $buildargString" Debug
    
            $EXEPath = "docker"
            $options = "build $buildargString -t $FQImageName ."
        
            $return = Start-MyProcess -EXEPath  $EXEPath -options $options
        
            if ($logLevel -eq "Debug"){
                #Only show the stdout stream if we are in debugging logLevel
                $return.stdout
            }
            if (-not [string]::IsNullOrEmpty($return.stderr)){
                Write-Log "$($return.stderr)" Warning
                Write-Log "There was an error of some type. See warning above for more info" Error
            }
         
        }
    } Export-ModuleMember -Function Invoke-DockerImageBuild