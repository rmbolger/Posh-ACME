Describe "Export-PACertFiles" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "No account" {
        It "Throws" {
            Mock -ModuleName Posh-ACME Get-PAAccount {}
            InModuleScope Posh-ACME {
                { Export-PACertFiles } | Should -Throw "*No ACME account*"
            }
        }
    }

    Context "No current order" {
        # pretend there's no current order
        BeforeAll {
            Mock Write-Warning {}
            InModuleScope Posh-ACME { $script:Order = $null }
        }

        It "No params - Throws" {
            InModuleScope Posh-ACME {
                { Export-PACertFiles } | Should -Throw "*No ACME order*"
            }
        }


    }

    # It "Returns chain file issuer data" {
    #     InModuleScope Posh-ACME {
    #         $issuers = Get-ChainIssuers -OrderFolder 'TestDrive:\'
    #         $issuers | Should -HaveCount 3
    #         $issuers[0].issuer | Should -Be 'Fake ISRG Root X1'
    #         $issuers[0].filepath | Should -BeLike '*\chain0.cer'
    #         $issuers[0].index | Should -Be 0
    #         $issuers[1].issuer | Should -Be 'Fake DST Root CA X3'
    #         $issuers[1].filepath | Should -BeLike '*\chain0.cer'
    #         $issuers[1].index | Should -Be 1
    #         $issuers[2].issuer | Should -Be 'Fake ISRG Root X1'
    #         $issuers[2].filepath | Should -BeLike '*\chain1.cer'
    #         $issuers[2].index | Should -Be 0
    #     }
    # }

}
