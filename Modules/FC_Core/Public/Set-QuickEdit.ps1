# https://stackoverflow.com/a/42792718/1944366

$QuickEditCodeSnippet=@" 
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;


public static class DisableConsoleQuickEdit
{

const uint ENABLE_QUICK_EDIT = 0x0040;

// STD_INPUT_HANDLE (DWORD): -10 is the standard input device.
const int STD_INPUT_HANDLE = -10;

[DllImport("kernel32.dll", SetLastError = true)]
static extern IntPtr GetStdHandle(int nStdHandle);

[DllImport("kernel32.dll")]
static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);

[DllImport("kernel32.dll")]
static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

public static bool SetQuickEdit(bool SetEnabled)
{

    IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);

    // get current console mode
    uint consoleMode;
    if (!GetConsoleMode(consoleHandle, out consoleMode))
    {
        // ERROR: Unable to get console mode.
        return false;
    }

    // Clear the quick edit bit in the mode flags
    if (SetEnabled)
    {
        consoleMode &= ~ENABLE_QUICK_EDIT;
    }
    else
    {
        consoleMode |= ENABLE_QUICK_EDIT;
    }

    // set the new mode
    if (!SetConsoleMode(consoleHandle, consoleMode))
    {
        // ERROR: Unable to set console mode
        return false;
    }

    return true;
}
}

"@

$QuickEditMode=add-type -TypeDefinition $QuickEditCodeSnippet -Language CSharp


function Set-QuickEdit() 
{
    <#
    .Synopsis
        Changes the quick edit mode of the active console host window; useful to prevent scripts from pausing while running
    .DESCRIPTION
       
    .EXAMPLE
        Set-QuickEdit -DisableQuickEdit
    .OUTPUTS
        
    .NOTES 
    Author: Krisz
    https://stackoverflow.com/a/42792718/1944366
    #>
[CmdletBinding()]
param(
[Parameter(Mandatory=$false, HelpMessage="This switch will disable Console QuickEdit option")]
    [switch]$DisableQuickEdit=$false
)


    if([DisableConsoleQuickEdit]::SetQuickEdit($DisableQuickEdit))
    {
        Write-Output "QuickEdit settings has been updated." 
    }
    else
    {
        Write-Output "Something went wrong."
    }
}

Export-ModuleMember -Function Set-QuickEdit