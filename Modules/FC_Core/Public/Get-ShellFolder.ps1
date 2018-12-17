function Get-ShellFolder{
param([Parameter(ValueFromPipeline)][string[]]$folder)
    process{
        $objShell = New-Object -ComObject Shell.Application
        $outThing = $objShell.namespace("$folder")
        Write-Output $outThing
    }
}Export-ModuleMember -Function Get-ShellFolder