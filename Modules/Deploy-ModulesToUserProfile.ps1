<#
    .Synopsis
      Copies the friendly-chainsaw module files over to the user's Module directory in their profile. This is useful to install these modules on our TFS build boxes. 
    .EXAMPLE
        Deploy to 2 of our build boxes. Must specify the service account, or it will copy the modules over to the user profile who ran the script. 

        .\Deploy-ModulesToUserProfile.ps1 -computers vwehstfsbld01,vwehstfsbld02 -users ehstfsservice
#>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([Parameter(position=0)][ValidateSet("Debug","Info","Warning","Error", "Disable")][string] $logLevel = "Info"
,[switch] $winEventLog
,[string[]] $computers = $null
,[string[]] $users = $null)

if ($computers -eq $null){
    $destDir = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"

    Copy-Item -Path .\* -Destination $destDir -Force -Recurse -Exclude "*.ps1","*.xml"
}
else{
    foreach($pc in $computers){
        if ($users -eq $null){
            $destDir = "\\$pc\C$\Users\$env:USERNAME\Documents\WindowsPowerShell\Modules"

            if (!(test-path $destDir)){
                mkdir $destDir
            }
            Copy-Item -Path .\* -Destination $destDir -Force -Recurse -Exclude "*.ps1","*.xml" 
        }
        else{
            foreach ($user in $users){
                $destDir = "\\$pc\C$\Users\$user\Documents\WindowsPowerShell\Modules"

                if (!(test-path $destDir)){
                    mkdir $destDir
                }

                Copy-Item -Path .\* -Destination $destDir -Force -Recurse -Exclude "*.ps1","*.xml"
            }
        }
    }
}