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
            InModuleScope Posh-ACME {
                Import-PAConfig
                $script:Order = $null
            }
        }

        It "No params - Throws" {
            InModuleScope Posh-ACME {
                { Export-PACertFiles } | Should -Throw "*No ACME order*"
            }
        }
    }

    Context "Expired Order" {

        # An expired order should use cached cert/chain files and our test
        # chain0.cer and chain1.cer are copies of the new default chains
        # in Staging that highlight issue #315:
        # https://github.com/rmbolger/Posh-ACME/issues/315
        #
        # chain0 = (STAGING) Pretend Pear X1 <- (STAGING) Doctored Durian Root CA X3
        # chain1 = (STAGING) Pretend Pear X1

        BeforeAll {
            Mock Write-Warning {}
            Mock Copy-Item {}
            Mock -ModuleName Posh-ACME Export-Pem {}
            Mock -ModuleName Posh-ACME Export-CertPfx {}
            InModuleScope Posh-ACME {
                Import-PAConfig
                $script:Order.expires = [DateTime]::Now.AddDays(-1).ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
            }
        }

        It "Uses chain0 when no PreferredChain" {
            InModuleScope Posh-ACME {
                $script:Order | Add-Member PreferredChain $null -Force
                { Export-PACertFiles } | Should -Not -Throw
            }
            Should -Invoke Write-Warning
            Should -Invoke Copy-Item -Times 1 -Exactly -ParameterFilter {
                $Path -like '*chain0.cer' -and $Destination -like '*chain.cer'
            }
            Should -Invoke Export-Pem -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter {
                $OutputFile -like '*fullchain.cer'
            }
            Should -Invoke Export-CertPfx -ModuleName Posh-ACME -Times 2 -Exactly
        }

        It "Uses chain0 when PreferredChain (STAGING) Doctored Durian Root CA X3" {
            InModuleScope Posh-ACME {
                $script:Order | Add-Member PreferredChain "(STAGING) Doctored Durian Root CA X3" -Force
                { Export-PACertFiles } | Should -Not -Throw
            }
            Should -Invoke Write-Warning
            Should -Invoke Copy-Item -Times 1 -Exactly -ParameterFilter {
                $Path -like '*chain0.cer' -and $Destination -like '*chain.cer'
            }
            Should -Invoke Export-Pem -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter {
                $OutputFile -like '*fullchain.cer'
            }
            Should -Invoke Export-CertPfx -ModuleName Posh-ACME -Times 2 -Exactly
        }

        It "Uses chain1 when PreferredChain (STAGING) Pretend Pear X1" {
            InModuleScope Posh-ACME {
                $script:Order | Add-Member PreferredChain "(STAGING) Pretend Pear X1" -Force
                { Export-PACertFiles } | Should -Not -Throw
            }
            Should -Invoke Write-Warning
            Should -Invoke Copy-Item -Times 1 -Exactly -ParameterFilter {
                $Path -like '*chain1.cer' -and $Destination -like '*chain.cer'
            }
            Should -Invoke Export-Pem -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter {
                $OutputFile -like '*fullchain.cer'
            }
            Should -Invoke Export-CertPfx -ModuleName Posh-ACME -Times 2 -Exactly
        }

    }

}
