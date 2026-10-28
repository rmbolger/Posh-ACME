Describe 'Export-PAAccountKey' {
    BeforeAll {
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Destination 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    It 'Exports the current account key as PKCS8 PEM' {
        $outputFile = Join-Path $TestDrive 'account-key.pem'
        $pem = InModuleScope Posh-ACME -Parameters @{ OutputFile = $outputFile } {
            param($OutputFile)

            Export-PAAccountKey -OutputFile $OutputFile -Force
            [IO.File]::ReadAllText($OutputFile)
        }

        $pem | Should -Match '^-----BEGIN PRIVATE KEY-----'
        $pem | Should -Match "-----END PRIVATE KEY-----`n\z"
        $pem | Should -Not -Match "`r"
    }

    It 'Exports the current account key as SEC1 PEM with LegacyFormat' {
        $outputFile = Join-Path $TestDrive 'account-key-legacy.pem'
        $pem = InModuleScope Posh-ACME -Parameters @{ OutputFile = $outputFile } {
            param($OutputFile)

            Export-PAAccountKey -OutputFile $OutputFile -Force -LegacyFormat
            [IO.File]::ReadAllText($OutputFile)
        }

        $pem | Should -Match '^-----BEGIN EC PRIVATE KEY-----'
        $pem | Should -Match "-----END EC PRIVATE KEY-----`n\z"
        $pem | Should -Not -Match "`r"
    }
}
