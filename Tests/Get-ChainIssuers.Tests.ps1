Describe "Get-ChainIssuers" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    It "Returns chain file issuer data" {
        InModuleScope Posh-ACME {
            $issuers = Get-ChainIssuers -OrderFolder 'TestDrive:\acme.test\11111\example.com'
            $issuers | Should -HaveCount 3
            $issuers[0].issuer | Should -Be '(STAGING) Pretend Pear X1'
            $issuers[0].filepath | Should -BeLike '*chain0.cer'
            $issuers[0].index | Should -Be 1
            $issuers[1].issuer | Should -Be '(STAGING) Doctored Durian Root CA X3'
            $issuers[1].filepath | Should -BeLike '*chain0.cer'
            $issuers[1].index | Should -Be 0
            $issuers[2].issuer | Should -Be '(STAGING) Pretend Pear X1'
            $issuers[2].filepath | Should -BeLike '*chain1.cer'
            $issuers[2].index | Should -Be 0
        }
    }

}
