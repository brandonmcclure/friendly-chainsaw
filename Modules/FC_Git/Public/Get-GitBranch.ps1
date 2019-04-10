function Get-GitBranch {
param([switch] $returnAllBranches)
  if (!([string]::IsNullOrEmpty($env:BUILD_SOURCEBRANCHNAME))) {
    Write-Log "Running inside a TFS build/release, returning the TFS varaible: BUILD_SOURCEBRANCHNAME" Debug
    Write-Output $env:BUILD_SOURCEBRANCHNAME
  }
  else {
    $result = Start-MyProcess "git" "branch" -sleepTimer 0
    Write-Log "Value of git command: $a" Debug

    if ([string]::IsNullOrEmpty($result.stdout) ){
      Write-Output ""
    }
    else {
        if ($returnAllBranches){
            Write-Output ($result.stdout.Replace(' ?*?','') -split("`n"))
        }
        else{
            $array = $result.stdout -split("`n") | where {-not [string]::IsNullOrEmpty($_)}
          $output = $array | Where-Object { $_.Substring(0,1) -eq '*' }
          $length = $output.Length
          Write-Output ($output.Substring(2,$length - 2))
      }
  }
  }
} Export-ModuleMember -Function Get-GitBranch
