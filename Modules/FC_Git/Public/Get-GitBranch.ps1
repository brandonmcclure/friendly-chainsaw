function Get-GitBranch {
param([switch] $returnAllBranches)
  Write-Log "This command was deprecated in 5.0, switch to posh-git's get-gitstatus." Warning
  if (!([string]::IsNullOrEmpty($env:BUILD_SOURCEBRANCHNAME))) {
    Write-Log "Running inside a TFS build/release, returning the TFS varaible: BUILD_SOURCEBRANCHNAME" Debug
    Write-Output $env:BUILD_SOURCEBRANCHNAME
  }
  else {
    try {
      Import-Module posh-git
    }
    catch
    {
      Write-Log "If posh-git is not installed will attempt to install and use that, otherwise will error" Warning
      Install-Module -Name posh-git -Repository PSGallery -Force
      Import-Module posh-git
    }
    
    if ([string]::IsNullOrEmpty((get-gitstatus))) {
      Write-Output ""
    }
    else {
        if ($returnAllBranches){
            Write-Error "We have not implemented a fix for this that uses posh-git"
        }
        else{
          (get-gitstatus).branch
      }
  }
  }
} Export-ModuleMember -Function Get-GitBranch
