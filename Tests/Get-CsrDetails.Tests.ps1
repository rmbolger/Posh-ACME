Describe "Get-CsrDetails" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "Missing CSR file" {
        It "Throws if file doesn't exist" {
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\noexist.csr' } | Should -Throw
            }
        }
    }

    Context "Invalid CSR" {
        It "Throws if invalid" {
            Copy-Item "$PSScriptRoot\TestFiles\invalid.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Throw
            }
        }
    }

    Context "No CN and No SANs" {
        It "Throws if no names found" {
            Copy-Item "$PSScriptRoot\TestFiles\noCN-noSANs.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Throw
            }
        }
    }

    Context "EC-192 based CSR" {
        It "Throws on unsupported curve" {
            Copy-Item "$PSScriptRoot\TestFiles\ec-192-basic.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Throw
            }
        }
    }

    Context "RSA 1024 based CSR" {
        It "Throws on RSA out of range" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-1024-basic.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Throw
            }
        }
    }

    Context "RSA 2048 CSR" {
        It "Reads properly" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-noCN-singleSAN.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
            }
        }
    }

    Context "RSA 4096 CSR" {
        It "Reads properly" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-4096-soloCN-noSANs-ocsp.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr'} | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly "4096"
                $result.OCSPMustStaple | Should -BeTrue
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
            }
        }
    }

    Context "EC 256 CSR" {
        It "Reads properly" {
            Copy-Item "$PSScriptRoot\TestFiles\ec-256-wildcardCN-multiSANs.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('*.example.com','example.com','*.sub1.example.com')
                $result.KeyLength      | Should -BeExactly "ec-256"
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
            }
        }
    }

    Context "EC 521 CSR" {
        It "Reads properly" {
            Copy-Item "$PSScriptRoot\TestFiles\ec-521-complexCN-SANsNoDns.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly "ec-521"
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
            }
        }
    }

}
