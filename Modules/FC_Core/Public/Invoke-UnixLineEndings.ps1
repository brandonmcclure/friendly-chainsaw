function Invoke-UnixLineEndings{
    param($directory
    ,$maxSize = 1000000
    ,$excludeExtensions = @(".zip")
    )

If (-Not (Test-Path $directory)){
    Write-Error "Could not find directory at $directory" -ErrorAction Stop
}
Write-Verbose "Ensuring unix/lf line endings in text files"
$files = Get-ChildItem -Path $directory -File -ErrorAction Stop -Recurse | Where {$_.Extension -notin $excludeExtensions}
foreach ($file in $files) {
    if ($file.Length -gt $maxSize) {
        Write-Warning "I can't process a file larger than 1 MB, skipping"
        Continue
    }
    $text = [IO.File]::ReadAllText($file.FullName) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($file.FullName, $text)
}
}Export-ModuleMember -Function Invoke-UnixLineEndings