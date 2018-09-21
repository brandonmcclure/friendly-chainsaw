function Get-GitLastCommit {
<#
    .Synopsis
      Returns the full SHA1 commit hash for the most recent commit of the current branch
    .DESCRIPTION
      Will return an empty string if there is an error. 
    .PARAMETER path
        Optional
        Default: Null

        The path to the folder or file that you want to get the most recent commit from. Needs to be relative to the root of the repository. 

    .PARAMETER masterBranch
        Optional
        Default: $false

        This is kind of hacky so forgive me. If this switch is true, this will get the most recent commit hash from the local master branch, if false, it will look at the HEAD (or the current branch)
        I tried to parameterize this so you could choose which branch to get the commit, but I was getting errors which i believe was jsut the way I was formatting the invocation of the git.exe
       
    .EXAMPLE
        Get the most recent commit hash of the entire repository, for the current branch

        Get-GitLastCommit

        Output: dcef3a70cc28d9dfa058c8f86183cef6e78a6df5

    .EXAMPLE
        Get the most recent commit hash of a specific directory (named SSAS_TabularModels), for the current branch

        Get-GitLastCommit "SSAS_TabularModels"

        Output: 798bbd1d8d27b99ea27ff2e38e3ae86f4b02c317

    .EXAMPLE
        Get the most recent commit hash of a specific file in a subdirectory (named SSAS_TabularModels\.gitgnore on windows...), for the current branch

        Get-GitLastCommit "SSAS_TabularModels/.gitignore"

        Output: 6cb5d7854d5b81b407d475972ee602de9c7ddca3

    .EXAMPLE
        Get the most recent commit hash of a specific file in a subdirectory (named SSAS_TabularModels\.gitgnore on windows...), for the master branch

        Get-GitLastCommit "SSAS_TabularModels/.gitignore" -masterBranch

        Output: 6cb5d7854d5b81b407d475972ee602de9c7ddca3
    #>
  [CmdletBinding(SupportsShouldProcess = $true)]
  param([Parameter(Position = 0)] [string]$path = $null
    ,[Parameter(Position = 1)] [switch]$masterBranch = $false
  )

  Write-Verbose "Current Location: $(Get-Location)"
  $oldErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Stop"
  try {
    if (!([string]::IsNullOrEmpty($path))) {

      $path = $path -replace "\\","/"
      #This is crappy code... I was getting an error when I tried to parameterize this to allow you to specify what branch you want to get the last commit from. The error was :Path $path exists on disk but not in the index. 
      #When I outputted the call I am making, I was able to execute it on the command line just fine. Come find out the parameter that was located where "master" or "head" are is what was causing it. For the meantime, this works for my purposes. 
      #If theuser specifies, then get the commit from master. If not, get the commit of the current branch (HEAD)
      if ($masterBranch) {
        Write-Verbose "git rev-parse master:""$path"""
        $gitLogOutput = & git rev-parse master:'"'$path'"'
      }
      else {
        Write-Verbose "git rev-parse head:""$path"""
        $gitLogOutput = & git rev-parse head:'"'$path'"'
      }
    }
    else {
      if ($masterBranch) {
        Write-Verbose "git rev-parse master"
        $gitLogOutput = & git rev-parse master
      }
      else {
        Write-Verbose "git rev-parse HEAD"
        $gitLogOutput = & git rev-parse HEAD
      }

    }
  }
  catch {
    $gitLogOutput = ''
  }
  $ErrorActionPreference = $oldErrorAction
  Write-Output $gitLogOutput
} Export-ModuleMember -Function Get-GitLastCommit
