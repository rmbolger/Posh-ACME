Describe "New-Csr" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "OCSP Must-Staple" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Round-trips through Get-CsrDetails when <Name>" -TestCases @(
            @{ Name = 'enabled';  MustStaple = $true  }
            @{ Name = 'disabled'; MustStaple = $false }
        ) {
            InModuleScope Posh-ACME -Parameters @{ MustStaple = $MustStaple; CaseName = $Name } {
                param($MustStaple, $CaseName)

                $orderFolder = Join-Path 'TestDrive:\' "csr-$CaseName"
                New-Item -ItemType Directory -Path $orderFolder -Force | Out-Null

                $order = [pscustomobject]@{
                    PSTypeName     = 'PoshACME.PAOrder'
                    MainDomain     = 'example.com'
                    SANs           = @()
                    KeyLength      = 'ec-256'
                    Folder         = $orderFolder
                    OCSPMustStaple = $MustStaple
                    identifiers    = @([pscustomobject]@{ type = 'dns'; value = 'example.com' })
                }

                { New-Csr $order } | Should -Not -Throw
                $csr = New-Csr $order
                $csr | Should -Not -BeNullOrEmpty

                # New-Csr also writes the PEM request, which is what Get-CsrDetails can read
                $details = Get-CsrDetails (Join-Path $orderFolder 'request.csr')
                $details.OCSPMustStaple | Should -Be $MustStaple
                $details.Domain | Should -Be @('example.com')
            }
        }
    }
}
