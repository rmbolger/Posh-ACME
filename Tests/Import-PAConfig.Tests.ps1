Describe "Import-PAConfig" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "Module Load - Complete Config" {
        It "Sets Script Variables" {
            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}
                Import-PAConfig

                $script:Dir.Folder       | Should -Be (Join-Path $TestDrive 'acme.test')
                $script:Dir.location     | Should -Be 'https://acme.test/directory'
                $script:Acct.Folder      | Should -Be (Join-Path $TestDrive 'acme.test\11111')
                $script:Acct.id          | Should -Be 11111
                $script:Order.MainDomain | Should -Be 'example.com'
                Should -Invoke Set-CertValidation -ParameterFilter { $Skip -eq $false }
            }
        }
    }

    Context "Module Load - No Order" {

        BeforeAll {
            Get-ChildItem 'TestDrive:\acme.test\11111\' -Exclude 'acct.json' | Remove-Item -Force -Recurse
        }

        It "Sets Script Variables" {
            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}
                Import-PAConfig

                $script:Dir.Folder       | Should -Be (Join-Path $TestDrive 'acme.test')
                $script:Dir.location     | Should -Be 'https://acme.test/directory'
                $script:Acct.Folder      | Should -Be (Join-Path $TestDrive 'acme.test\11111')
                $script:Acct.id          | Should -Be 11111
                $script:Order            | Should -BeNullOrEmpty
                Should -Invoke Set-CertValidation -ParameterFilter { $Skip -eq $false }
            }
        }
    }

    Context "Module Load - No Account" {

        BeforeAll {
            Get-ChildItem 'TestDrive:\acme.test' -Exclude 'dir.json' | Remove-Item -Force -Recurse
        }

        It "Sets Script Variables" {
            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}
                Import-PAConfig

                $script:Dir.Folder       | Should -Be (Join-Path $TestDrive 'acme.test')
                $script:Dir.location     | Should -Be 'https://acme.test/directory'
                $script:Acct.Folder      | Should -BeNullOrEmpty
                $script:Acct             | Should -BeNullOrEmpty
                $script:Order            | Should -BeNullOrEmpty
                Should -Invoke Set-CertValidation -ParameterFilter { $Skip -eq $false }
            }
        }
    }

    Context "Module Load - No Server" {

        BeforeAll {
            Get-ChildItem 'TestDrive:\' | Remove-Item -Force -Recurse
        }

        It "Sets Script Variables" {
            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}
                Import-PAConfig

                $script:Dir.Folder       | Should -BeNullOrEmpty
                $script:Dir              | Should -BeNullOrEmpty
                $script:Acct.Folder      | Should -BeNullOrEmpty
                $script:Acct             | Should -BeNullOrEmpty
                $script:Order            | Should -BeNullOrEmpty
                Should -Not -Invoke Set-CertValidation
            }
        }
    }

    Context "Change Order" {

        BeforeAll {
            # reset config files to default
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            InModuleScope Posh-ACME {
                Import-PAConfig
            }
        }

        It "Sets Script Variables" {

            # mimic the result of a Set-PAOrder to the non-default order
            '*.example.com' | Out-File 'TestDrive:\acme.test\11111\current-order.txt' -Force

            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}

                Import-PAConfig -Level 'Order'

                $script:Dir.Folder       | Should -Be (Join-Path $TestDrive 'acme.test')
                $script:Dir.location     | Should -Be 'https://acme.test/directory'
                $script:Acct.Folder      | Should -Be (Join-Path $TestDrive 'acme.test\11111')
                $script:Acct.id          | Should -Be 11111
                $script:Order.MainDomain | Should -Be '*.example.com'
                Should -Not -Invoke Set-CertValidation
            }
        }
    }

    Context "Change Account" {

        BeforeAll {
            # reset config files to default
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            InModuleScope Posh-ACME {
                Import-PAConfig
            }
        }

        It "Sets Script Variables" {

            # mimic the result of a Set-PAAccount to the non-default account
            '22222' | Out-File 'TestDrive:\acme.test\current-account.txt' -Force

            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}

                Import-PAConfig -Level 'Account'

                $script:Dir.Folder       | Should -Be (Join-Path $TestDrive 'acme.test')
                $script:Dir.location     | Should -Be 'https://acme.test/directory'
                $script:Acct.Folder      | Should -Be (Join-Path $TestDrive 'acme.test\22222')
                $script:Acct.id          | Should -Be 22222
                $script:Order.MainDomain | Should -Be '*.example.org'
                Should -Not -Invoke Set-CertValidation
            }
        }
    }

    Context "Change Server" {

        BeforeAll {
            # reset config files to default
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            InModuleScope Posh-ACME {
                Import-PAConfig
            }
        }

        It "Sets Script Variables" {

            # mimic the result of a Set-PAServer to the non-default server
            'https://acme2.test/directory' | Out-File 'TestDrive:\current-server.txt' -Force

            InModuleScope Posh-ACME {
                Mock Set-CertValidation {}

                Import-PAConfig -Level 'Server'

                $script:Dir.Folder       | Should -Be (Join-Path $TestDrive 'acme2.test')
                $script:Dir.location     | Should -Be 'https://acme2.test/directory'
                $script:Acct.Folder      | Should -BeNullOrEmpty
                $script:Acct             | Should -BeNullOrEmpty
                $script:Order            | Should -BeNullOrEmpty
                Should -Invoke Set-CertValidation -ParameterFilter { $Skip -eq $true }
            }
        }
    }

    Context "v3 Plugin Data" {

        BeforeAll {
            # reset config files to default
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            # add a v3 plugindata.xml file to the account folder
            $xmlPath = 'TestDrive:\acme.test\11111\plugindata.xml'
            @{R53ProfileName='myprofile'; DOToken='xxxxx'} | Export-CliXml $xmlPath
            $xmlContent = Get-Content $xmlPath -Raw
        }

        It "Extracts order specific args to JSON" {
            InModuleScope Posh-ACME {
                Mock Get-PAOrder { @(
                    [pscustomobject]@{MainDomain='example.com';Plugin=@('Route53')}
                    [pscustomobject]@{MainDomain='*.example.com';Plugin=@('DOcean')}
                )}
                Mock Export-PluginArgs {}
                Import-PAConfig
                Should -Invoke Export-PluginArgs -Exactly 2 -ParameterFilter {
                    $MainDomain -in 'example.com','*.example.com' -and
                    $Plugin -in 'Route53','DOcean'
                }
            }
        }

        It "Renames XML to v3" {
            $xmlPath      | Should -Not -Exist
            "$xmlPath.v3" | Should -Exist
            Get-Content "$xmlPath.v3" -Raw | Should -Be $xmlContent
        }
    }


}
