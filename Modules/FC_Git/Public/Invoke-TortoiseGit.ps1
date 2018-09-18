Function Invoke-TortoiseGit{
<#
    .SYNOPSIS
        Runs tortoiseGit UI from command line. View the TortoiseGit help documentation by running one of the following:
        
            tGit
            tGit help 
    .PARAMETER cmd
        Required

        The comamnd sent to tortoise git. run one of the following to view the TortoiseGit help documentation, and what valid options are.:

        tGit
        tGit help
        
    .PARAMETER path
        Optional
        Default = current directory

        The path passed to tortoise git. (for file renames, file log, or commiting individual directories or files.

    .EXAMPLE
        Shows the UI for a history of the file named myFile.txt in the current directory.

        tGit log .\myFile.txt

    .EXAMPLE
        Opens the commit UI for the current directory.

        tGit commit
    .LINKS
        https://ayende.com/blog/4749/executing-tortoisegit-from-the-command-line
#>
param([Parameter(position=0)] $cmd,
[Parameter(position=1)] $path
)
        $tGitPath = 'TortoiseGitProc.exe'
    
        if ([string]::IsNullOrEmpty($cmd)){
            & $tGitPath /command:help /path:.
        }
        else{
            if ([string]::IsNullOrEmpty($path)){
                & $tGitPath /command:$cmd /path:.
            }
            else{
                Write-log "Path: $path" Debug
                & $tGitPath /command:$cmd /path:$path
            }
        }


}Export-ModuleMember -Function Invoke-TortoiseGit -Alias tGit