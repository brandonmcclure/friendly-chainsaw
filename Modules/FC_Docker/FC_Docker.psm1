#Parts of a docker fully qualified image name
class DockerFQName{
    [string]$Registry
	[string]$Repository
	[string]$Image
	[string]$Tag
	[String]$FQN

	DockerFQName($registry,$repository,$image,$tag){
        if([string]::IsNullOrEmpty($registry) -or $registry.EndsWith('/')){
			$this.Registry = ($registry ?? "").tolower()
		}else{
			$this.Registry = ($registry ?? "").tolower()+'/'
		}
		if([string]::IsNullOrEmpty($repository) -or $repository.EndsWith('/')){
			$this.Repository = ($repository ?? "").tolower()
		}else{
			$this.Repository = ($repository ?? "").tolower()+'/'
		}
		$this.Image = ($image ?? "").tolower()

		if([string]::IsNullOrEmpty($tag)){
			$this.Tag = "latest"
		}
		else{

			$this.Tag = ($tag.replace(":","")).tolower()
		}
		$this.FQN = "$($this.Registry)$($this.Repository)$($this.Image):$($this.Tag)"
    }
}

Write-Verbose "Importing Functions"

# Import everything in sub folders folder 
foreach ($folder in @('private','public','classes'))
{
  $root = Join-Path -Path $PSScriptRoot -ChildPath $folder
  if (Test-Path -Path $root)
  {
    Write-Verbose "processing folder $root"
    $files = Get-ChildItem -Path $root -Filter *.ps1


    # dot source each file 
    $files | Where-Object { $_.Name -notlike '*.Tests.ps1' } |
    ForEach-Object { Write-Verbose $_.Name;.$_.FullName }
  }
}