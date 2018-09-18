Function Get-GitBranch{
if (!([string]::IsNullOrEmpty($env:BUILD_SOURCEBRANCHNAME))){
    Write-Log "Running inside a TFS build/release, returning the TFS varaible: BUILD_SOURCEBRANCHNAME" Debug
    Write-Output $env:BUILD_SOURCEBRANCHNAME
}
else{
    $a = @()
    $a = & git branch

    Write-Log "Value of git command: $a" Debug

    if ([string]::IsNullOrEmpty($a)){
        Write-Output ""
    }
    else{
        $output = $a | where {$_.substring(0,1) -eq '*'}
        $length = $output.length
        write-output ($output.substring(2,$length-2))
    }
}
}Export-ModuleMember -Function Get-GitBranch