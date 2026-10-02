Describe "Get-CsrDetails" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
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

    Context "RSA 2048 CSR no attributes" {
        It "Reads properly" {
            Mock -ModuleName Posh-ACME Write-Warning {}
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-onlyCN-no-attrs.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                Should -Invoke Write-Warning
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 15
            }
        }
    }

    Context "RSA 2048 CSR" {
        It "Reads properly from File" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-noCN-singleSAN.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 19
            }
        }

        It "Reads properly from String" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-noCN-singleSAN.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                $csrString = Get-Content 'TestDrive:\test.csr' -Raw
                { Get-CsrDetails -CSRPath $csrString } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath $csrString
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 19
            }
        }
    }

    Context "RSA 2048 CSR Single Line Base64" {
        It "Reads properly from File" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-noCN-singleSAN-singleLine.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 3
            }
        }

        It "Reads properly from String" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-noCN-singleSAN-singleLine.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                $csrString = Get-Content 'TestDrive:\test.csr' -Raw
                { Get-CsrDetails -CSRPath $csrString } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath $csrString
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 3
            }
        }
    }

    Context "RSA 2048 CSR with critical extensions" {
        It "Reads properly" {
            Copy-Item "$PSScriptRoot\TestFiles\rsa-2048-noCN-criticalSAN.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                { Get-CsrDetails -CSRPath 'TestDrive:\test.csr' } | Should -Not -Throw
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'
                $result.Domain         | Should -BeExactly @('example.com')
                $result.KeyLength      | Should -BeExactly '2048'
                $result.OCSPMustStaple | Should -BeTrue
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 16
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
                $result.PemLines.Count | Should -Be 28
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
                $result.PemLines.Count | Should -Be 11
            }
        }
    }

    Context "EC 256 CSR with IP SAN" {
        It "Includes IP address SAN entries in Domain" {
            Copy-Item "$PSScriptRoot\TestFiles\ec-256-san-with-ip.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr'

                $result.Domain.Count | Should -Be 3
                $result.Domain[0] | Should -BeExactly 'example.com'
                $result.Domain[1] | Should -BeExactly '192.0.2.1'
                $result.Domain[2] | Should -BeExactly '2001:db8::1'
                $result.KeyLength | Should -BeExactly 'ec-256'
                $result.OCSPMustStaple | Should -BeFalse
            }
        }
    }

    Context "EC 521 CSR" {
        It "Reads properly" {
            Copy-Item "$PSScriptRoot\TestFiles\ec-521-complexCN-SANsNoDns.csr" 'TestDrive:\test.csr'
            InModuleScope Posh-ACME {
                $result = Get-CsrDetails -CSRPath 'TestDrive:\test.csr' -WarningVariable sanWarnings -WarningAction SilentlyContinue
                $result.Domain | Should -BeExactly @('example.com','127.0.0.1','192.168.0.1')
                $result.KeyLength      | Should -BeExactly "ec-521"
                $result.OCSPMustStaple | Should -BeFalse
                { $result.Base64Url | ConvertFrom-Base64Url } | Should -Not -Throw
                $result.PemLines.Count | Should -Be 13
                $sanWarnings.Count | Should -Be 2
                $sanWarnings.Message -join ' ' | Should -Match 'TagNo 1'
                $sanWarnings.Message -join ' ' | Should -Match 'TagNo 6'
            }
        }
    }

}
