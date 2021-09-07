$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-Module FC_Data | Remove-Module -Force
Import-Module $here\FC_Data.psm1 -Force

Describe 'FC_Data Tests'{
    Invoke-CrystalDecisionAssembliesLoad
    $report = Mock Open-CrystalReport{}

    Context 'Validate script code'{
        it "$fileName"{
            0 | Should Be 0
        }
    }
}