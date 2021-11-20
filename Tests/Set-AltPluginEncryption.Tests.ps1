Describe "Set-AltPluginEncryption" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "Local Secret - 3 Orders" {

        BeforeAll {
            $env:POSHACME_VAULT_NAME = $null
            $env:POSHACME_VAULT_PASS = $null
            $env:POSHACME_VAULT_SECRET_TEMPLATE = $null
        }

        BeforeEach {
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse -Force

            InModuleScope -ModuleName Posh-ACME {
                Mock New-AesKey { 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' }
                Mock New-Guid { 'fakeguid' }
                Mock Export-PluginArgs {}
            }
        }

        It "Enables Alt Encryption" {
            InModuleScope -ModuleName Posh-ACME {
                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey | Should -Be 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Resets Alt Encryption Key" {
            InModuleScope -ModuleName Posh-ACME {
                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable -Reset

                $acct = Get-PAAccount
                $acct.sskey | Should -Be 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Disables Alt Encryption" {
            InModuleScope -ModuleName Posh-ACME {
                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable:$false

                $acct = Get-PAAccount
                $acct.sskey | Should -BeNullOrEmpty

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Ignores Enable When Already Enabled" {
            InModuleScope -ModuleName Posh-ACME {
                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey | Should -Be 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'

                Should -Invoke Export-PluginArgs -Times 0
            }
        }

        It "Ignores Disable When Already Disabled" {
            InModuleScope -ModuleName Posh-ACME {
                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable:$false

                $acct = Get-PAAccount
                $acct.sskey | Should -BeNullOrEmpty

                Should -Invoke Export-PluginArgs -Times 0
            }
        }

        It "Doesn't Change Active Account" {
            InModuleScope -ModuleName Posh-ACME {

                Mock Update-PAAccount {}

                # set a different account as active
                Import-PAConfig
                Set-PAAccount -ID acct2
                Get-PAAccount -ID acct1 | Set-AltPluginEncryption -Enable

                # make sure we updated the right account
                $acct = Get-PAAccount -ID acct1
                $acct.id    | Should -Be 'acct1'
                $acct.sskey | Should -Be 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'

                Should -Invoke Export-PluginArgs -Times 3

                # make sure original account is still active
                (Get-PAAccount).id | Should -Be 'acct2'
            }
        }
    }

    Context "Vault Secret - 3 Orders" {

        BeforeAll {
            $env:POSHACME_VAULT_NAME = 'fake-vault'
            $env:POSHACME_VAULT_PASS = $null
            $env:POSHACME_VAULT_SECRET_TEMPLATE = $null
        }

        BeforeEach {
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse -Force

            InModuleScope -ModuleName Posh-ACME {
                Mock New-AesKey { 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' }
                Mock New-Guid { 'fakeguid' }
                Mock Export-PluginArgs {}
                Mock Set-Secret {}
                Mock Unlock-SecretVault {}
            }
        }

        It "Enables Alt Encryption" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret {}
                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'VAULT'
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'fake-vault' -and
                    $Name -eq 'poshacme-fakeguid-sskey' -and
                    $Secret -eq 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
                }

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Enables Alt Encryption - Existing Secret" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'VAULT'
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -Times 0

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Ignores Enable When Already Enabled" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }

                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'VAULT' -Force
                $acct | Add-Member 'VaultGuid' 'fakeguid' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey | Should -Be 'VAULT'

                Should -Invoke Export-PluginArgs -Times 0
            }
        }

        It "Resets Alt Encryption - Old Local" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret {}

                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable -Reset

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'VAULT'
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'fake-vault' -and
                    $Name -eq 'poshacme-fakeguid-sskey' -and
                    $Secret -eq 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
                }

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Resets Alt Encryption - Old Vault" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }

                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'VAULT' -Force
                $acct | Add-Member 'VaultGuid' 'fakeguid' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable -Reset

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'VAULT'
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'fake-vault' -and
                    $Name -eq 'poshacme-fakeguid-sskey' -and
                    $Secret -eq 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
                }

                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Disables Alt Encryption - Old Vault" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret { 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }

                # set an old fake sskey on the account
                $acct = Get-Content TestDrive:\srvr1\acct1\acct.json -Raw | ConvertFrom-Json
                $acct | Add-Member 'sskey' 'VAULT' -Force
                $acct | Add-Member 'VaultGuid' 'fakeguid' -Force
                $acct | ConvertTo-Json | Out-File TestDrive:\srvr1\acct1\acct.json

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable:$false

                $acct = Get-PAAccount
                $acct.sskey     | Should -BeNullOrEmpty
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -Times 0
                Should -Invoke Export-PluginArgs -Times 3
            }
        }

        It "Falls Back to Local When SecretManagmenet Missing" {
            InModuleScope -ModuleName Posh-ACME {
                # mimic SecretManagement not being installed
                Mock Get-Command {} -ParameterFilter {
                    $Name -in 'Unlock-SecretVault','Get-Secret'
                }
                Mock Write-Warning {}

                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'

                Should -Invoke Set-Secret -Times 0
                Should -Invoke Export-PluginArgs -Times 3
                Should -Invoke Write-Warning -ParameterFilter {
                    $Message -like 'Unable to save encryption key to secret vault*'
                }
            }
        }

        It "Attempts to Unlock Vault When Specified" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret {}
                $env:POSHACME_VAULT_PASS = 'fakepass'
                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'VAULT'
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'fake-vault' -and
                    $Name -eq 'poshacme-fakeguid-sskey' -and
                    $Secret -eq 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
                }

                Should -Invoke Export-PluginArgs -Times 3
                Should -Invoke Unlock-SecretVault -Times 1

                $env:POSHACME_VAULT_PASS = $null
            }
        }

        It "Uses Custom Secret Template When Specified" {
            InModuleScope -ModuleName Posh-ACME {
                Mock Get-Secret {}
                $env:POSHACME_VAULT_SECRET_TEMPLATE = 'mytemplate{0}'
                Import-PAConfig
                Get-PAAccount | Set-AltPluginEncryption -Enable

                $acct = Get-PAAccount
                $acct.sskey     | Should -Be 'VAULT'
                $acct.VaultGuid | Should -Be 'fakeguid'

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'fake-vault' -and
                    $Name -eq 'mytemplatefakeguid' -and
                    $Secret -eq 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
                }

                Should -Invoke Export-PluginArgs -Times 3

                $env:POSHACME_VAULT_SECRET_TEMPLATE = $null
            }
        }

    }

}
