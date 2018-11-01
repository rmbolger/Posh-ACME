Get-Module Posh-ACME | Remove-Module -Force
Import-Module $PSScriptRoot\..\Posh-ACME\Posh-ACME.psm1 -Force

Describe "Get-CsrDetails" {

    InModuleScope Posh-ACME {

        Context "Missing CSR file" {
            $missingFile = [System.IO.Path]::GetTempFileName();
            Remove-Item $missingFile
            It "Throws if file doesn't exist" {
                {Get-CsrDetails -CSRPath $missingFile} | Should -Throw
            }
        }
        Context "Invalid CSR" {
            $testFile = "$PSScriptRoot\TestFiles\invalid.csr"
            It "Throws if invalid" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Throw
            }
        }
        Context "No CN and No SANs" {
            $testFile = "$PSScriptRoot\TestFiles\noCN-noSANs.csr"
            It "Throws if no names found" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Throw
            }
        }
        Context "EC-192 based CSR" {
            $testFile = "$PSScriptRoot\TestFiles\ec-192-basic.csr"
            It "Throws on unsupported curve" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Throw
            }
        }
        Context "RSA 1024 based CSR" {
            $testFile = "$PSScriptRoot\TestFiles\rsa-1024-basic.csr"
            It "Throws on RSA out of range" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Throw
            }
        }
        Context "RSA 2048 CSR" {
            $testFile = "$PSScriptRoot\TestFiles\rsa-2048-noCN-singleSAN.csr"
            It "Should not throw with good file" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Not -Throw
            }
            $result = Get-CsrDetails -CSRPath $testFile
            It "'Domain' is correct" {
                $result.Domain | Should -BeExactly @('example.com')
            }
            It "'KeyLength' is correct" {
                $result.KeyLength | Should -BeExactly "2048"
            }
            It "'OCSPMustStaple is false" {
                $result.OCSPMustStaple | Should -BeFalse
            }
            It "'Base64Url' is parseable" {
                {$result.Base64Url | ConvertFrom-Base64Url} | Should -Not -Throw
            }
        }
        Context "RSA 4096 CSR" {
            $testFile = "$PSScriptRoot\TestFiles\rsa-4096-soloCN-noSANs-ocsp.csr"
            It "Should not throw with good file" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Not -Throw
            }
            $result = Get-CsrDetails -CSRPath $testFile
            It "'Domain' is correct" {
                $result.Domain | Should -BeExactly @('example.com')
            }
            It "'KeyLength' is correct" {
                $result.KeyLength | Should -BeExactly "4096"
            }
            It "'OCSPMustStaple is true" {
                $result.OCSPMustStaple | Should -BeTrue
            }
            It "'Base64Url' is parseable" {
                {$result.Base64Url | ConvertFrom-Base64Url} | Should -Not -Throw
            }
        }
        Context "EC 256 CSR" {
            $testFile = "$PSScriptRoot\TestFiles\ec-256-wildcardCN-multiSANs.csr"
            It "Should not throw with good file" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Not -Throw
            }
            $result = Get-CsrDetails -CSRPath $testFile
            It "'Domain' is correct" {
                $result.Domain | Should -BeExactly @('*.example.com','example.com','*.sub1.example.com')
            }
            It "'KeyLength' is correct" {
                $result.KeyLength | Should -BeExactly "ec-256"
            }
            It "'OCSPMustStaple is false" {
                $result.OCSPMustStaple | Should -BeFalse
            }
            It "'Base64Url' is parseable" {
                {$result.Base64Url | ConvertFrom-Base64Url} | Should -Not -Throw
            }
        }
        Context "EC 521 CSR" {
            $testFile = "$PSScriptRoot\TestFiles\ec-521-complexCN-SANsNoDns.csr"
            It "Should not throw with good file" {
                {Get-CsrDetails -CSRPath $testFile} | Should -Not -Throw
            }
            $result = Get-CsrDetails -CSRPath $testFile
            It "'Domain' is correct" {
                $result.Domain | Should -BeExactly @('example.com')
            }
            It "'KeyLength' is correct" {
                $result.KeyLength | Should -BeExactly "ec-521"
            }
            It "'OCSPMustStaple is false" {
                $result.OCSPMustStaple | Should -BeFalse
            }
            It "'Base64Url' is parseable" {
                {$result.Base64Url | ConvertFrom-Base64Url} | Should -Not -Throw
            }
        }
    }
}
