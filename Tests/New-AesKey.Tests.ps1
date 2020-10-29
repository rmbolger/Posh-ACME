Describe "New-AesKey" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    It "Throws on invalid sizes" -TestCases @(
        @{ BitLength = 1 }
        @{ BitLength = 64 }
        @{ BitLength = 127 }
        @{ BitLength = 257 }
        @{ BitLength = 512 }
    ) {
        InModuleScope Posh-ACME -Parameters @{BitLength = $BitLength} {
            param($BitLength)
            { New-AesKey $BitLength } | Should -Throw
        }
    }

    It "Creates valid keys with proper sizes" -TestCases @(
        @{ BitLength = 128 }
        @{ BitLength = 192 }
        @{ BitLength = 256 }
    ) {
        InModuleScope Posh-ACME -Parameters @{BitLength = $BitLength} {
            param($BitLength)

            { New-AesKey $BitLength } | Should -Not -Throw
            $result = New-AesKey $BitLength

            $result | Should -BeOfType [string]
            $bytes = $result | ConvertFrom-Base64Url -AsByteArray
            $bytes | Should -HaveCount ($BitLength/8)
        }
    }
}
