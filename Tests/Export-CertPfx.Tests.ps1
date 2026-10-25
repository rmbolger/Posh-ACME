Describe 'Export-CertPfx' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../Posh-ACME/Posh-ACME.psd1') -Force
        $fixtureRoot = Join-Path $PSScriptRoot 'TestFiles/ConfigRoot/srvr1/acct1/example.com'
    }

    It 'Writes a PFX file through CryptoHelper' {
        $outputFile = Join-Path $TestDrive 'fullchain.pfx'
        InModuleScope Posh-ACME -Parameters @{ FixtureRoot = $fixtureRoot; OutputFile = $outputFile } {
            param($FixtureRoot, $OutputFile)

            Export-CertPfx -CertFile (Join-Path $FixtureRoot 'cert.cer') `
                -KeyFile (Join-Path $FixtureRoot 'cert.key') `
                -ChainFile (Join-Path $FixtureRoot 'chain0.cer') `
                -OutputFile $OutputFile -PfxPass 'test-password'
        }

        Test-Path $outputFile | Should -BeTrue
        (Get-Item $outputFile).Length | Should -BeGreaterThan 0
    }
}
