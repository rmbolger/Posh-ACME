Describe "Get-PAOrder" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "No Server" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Get-PAServer {}
        }

        It "Throws Error" -ForEach @(
            @{ splat = @{                                                         } }
            @{ splat = @{                                           Refresh=$true } }
            @{ splat = @{ MainDomain='example.com';                               } }
            @{ splat = @{ MainDomain='example.com'; Name='altname'                } }
            @{ splat = @{                           Name='altname';               } }
            @{ splat = @{ MainDomain='example.com';                 Refresh=$true } }
            @{ splat = @{                           Name='altname'; Refresh=$true } }
            @{ splat = @{ MainDomain='*.example.com';                             } }
            @{ splat = @{ MainDomain='fake.test';                                 } }
            @{ splat = @{ List=$true                                              } }
            @{ splat = @{ List=$true; Refresh=$true                               } }
        ) {
            { Get-PAOrder @splat } | Should -Throw "*No ACME Server*"
        }
    }

    Context "No Accounts" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # remove all accounts
            Get-ChildItem 'TestDrive:\srvr1' -Exclude 'dir.json' | Remove-Item -Recurse -Force

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Throws Error" -ForEach @(
            @{ splat = @{                                                         } }
            @{ splat = @{                                           Refresh=$true } }
            @{ splat = @{ MainDomain='example.com';                               } }
            @{ splat = @{ MainDomain='example.com'; Name='altname'                } }
            @{ splat = @{                           Name='altname';               } }
            @{ splat = @{ MainDomain='example.com';                 Refresh=$true } }
            @{ splat = @{                           Name='altname'; Refresh=$true } }
            @{ splat = @{ MainDomain='*.example.com';                             } }
            @{ splat = @{ MainDomain='fake.test';                                 } }
            @{ splat = @{ List=$true                                              } }
            @{ splat = @{ List=$true; Refresh=$true                               } }
        ) {
            { Get-PAOrder @splat } | Should -Throw "*No ACME account*"
        }
    }

    Context "No Current Account" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # remove the current account
            Remove-Item 'TestDrive:\srvr1\current-account.txt'

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Throws Error" -ForEach @(
            @{ splat = @{                                                         } }
            @{ splat = @{                                           Refresh=$true } }
            @{ splat = @{ MainDomain='example.com';                               } }
            @{ splat = @{ MainDomain='example.com'; Name='altname'                } }
            @{ splat = @{                           Name='altname';               } }
            @{ splat = @{ MainDomain='example.com';                 Refresh=$true } }
            @{ splat = @{                           Name='altname'; Refresh=$true } }
            @{ splat = @{ MainDomain='*.example.com';                             } }
            @{ splat = @{ MainDomain='fake.test';                                 } }
            @{ splat = @{ List=$true                                              } }
            @{ splat = @{ List=$true; Refresh=$true                               } }
        ) {
            { Get-PAOrder @splat } | Should -Throw "*No ACME account*"
        }
    }

    Context "No Current Order" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # remove the current order
            Remove-Item 'TestDrive:\srvr1\acct1\current-order.txt'

            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Update-PAOrder {}
        }

        It "Returns Nothing for Current" -ForEach @(
            @{ splat = @{               } }
            @{ splat = @{ Refresh=$true } }
        ) {
            $order = Get-PAOrder @splat
            $order | Should -BeNullOrEmpty
            Should -Not -Invoke Update-PAOrder -ModuleName Posh-ACME
        }

    }

    Context "Current Order Legacy Wildcard" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # replace the current order with the wildcard main domain that might
            # exist from previous versions
            '*.example.com' | Out-File 'TestDrive:\srvr1\acct1\current-order.txt' -Force

            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Update-PAOrder {}
        }

        It "Returns Correct Data" -ForEach @(
            @{ splat = @{               } }
            @{ splat = @{ Refresh=$true } }
        ) {
            $order = Get-PAOrder @splat

            $order             | Should -Not -BeNullOrEmpty
            'PoshACME.PAOrder' | Should -BeIn $order.PSObject.TypeNames
            $order.Name        | Should -Be '!.example.com'
            $order.Folder      | Should -Be (Join-Path $TestDrive 'srvr1\acct1\!.example.com')
            $order.location    | Should -Be 'https://acme.test/acme/order/22222'

            if ($splat.Refresh) {
                Should -Invoke Update-PAOrder -Exactly 1 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Update-PAOrder -ModuleName Posh-ACME
            }
        }

    }

    Context "Current Order Custom Name" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # replace the current order with the wildcard main domain that might
            # exist from previous versions
            'altname' | Out-File 'TestDrive:\srvr1\acct1\current-order.txt' -Force

            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Update-PAOrder {}
        }

        It "Returns Correct Data" -ForEach @(
            @{ splat = @{               } }
            @{ splat = @{ Refresh=$true } }
        ) {
            $order = Get-PAOrder @splat

            $order             | Should -Not -BeNullOrEmpty
            'PoshACME.PAOrder' | Should -BeIn $order.PSObject.TypeNames
            $order.Name        | Should -Be 'altname'
            $order.Folder      | Should -Be (Join-Path $TestDrive 'srvr1\acct1\altname')
            $order.location    | Should -Be 'https://acme.test/acme/order/44444'

            if ($splat.Refresh) {
                Should -Invoke Update-PAOrder -Exactly 1 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Update-PAOrder -ModuleName Posh-ACME
            }
        }

    }

    Context "Test Config" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Update-PAOrder {}
        }

        It "Returns Nothing on No Match" -ForEach @(
            @{ splat = @{ MainDomain='fake.test';                                } }
            @{ splat = @{ MainDomain='fake.test';                  Refresh=$true } }
            @{ splat = @{                         Name='fakename';               } }
            @{ splat = @{                         Name='fakename'; Refresh=$true } }
            @{ splat = @{ MainDomain='fake.test'; Name='fakename';               } }
            @{ splat = @{ MainDomain='fake.test'; Name='fakename'; Refresh=$true } }
        ) {
            $order = Get-PAOrder @splat
            $order | Should -BeNullOrEmpty
            Should -Not -Invoke Update-PAOrder -ModuleName Posh-ACME
        }

        It "Returns Current and Specific Accounts" -ForEach @(
            @{ splat = @{                                                         }; Name='example.com'   }
            @{ splat = @{                                           Refresh=$true }; Name='example.com'   }
            @{ splat = @{ MainDomain='example.com';                               }; Name='example.com'   }
            @{ splat = @{ MainDomain='example.com';                 Refresh=$true }; Name='example.com'   }
            @{ splat = @{ MainDomain='example.com'; Name='altname'                }; Name='altname'       }
            @{ splat = @{                           Name='altname';               }; Name='altname'       }
            @{ splat = @{                           Name='altname'; Refresh=$true }; Name='altname'       }
            @{ splat = @{ MainDomain='*.example.com';                             }; Name='!.example.com' }
        ) {
            $order = Get-PAOrder @splat

            $order             | Should -Not -BeNullOrEmpty
            'PoshACME.PAOrder' | Should -BeIn $order.PSObject.TypeNames
            $order.Name        | Should -Be $Name
            $order.Folder      | Should -Be (Join-Path $TestDrive "srvr1\acct1\$Name")

            if ($splat.Refresh) {
                Should -Invoke Update-PAOrder -Exactly 1 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Update-PAOrder -ModuleName Posh-ACME
            }
        }

        It "Returns Correct Order Details" -ForEach @(
            @{ Name='!.example.com'; idCount=2; MainDomain='*.example.com'; location='https://acme.test/acme/order/22222' }
            @{ Name='altname';       idCount=1; MainDomain='example.com';   location='https://acme.test/acme/order/44444' }
            @{ Name='example.com';   idCount=1; MainDomain='example.com';   location='https://acme.test/acme/order/11111' }
        ) {
            $order = Get-PAOrder -Name $Name

            $order                   | Should -Not -BeNullOrEmpty
            'PoshACME.PAOrder'       | Should -BeIn $order.PSObject.TypeNames
            $order.Name              | Should -Be $Name
            $order.Folder            | Should -Be (Join-Path $TestDrive "srvr1\acct1\$Name")
            $order.identifiers.Count | Should -Be $idCount
            $order.MainDomain        | Should -Be $MainDomain
            $order.location          | Should -Be $location
            $order.expires           | Should -BeOfType [string]
            $order.DnsPlugin         | Should -BeNullOrEmpty
            $order.Plugin            | Should -Not -BeNullOrEmpty
            $order.PfxPassB64U       | Should -BeNullOrEmpty
            $order.PfxPass           | Should -Not -BeNullOrEmpty

        }

        It "Returns List Results" -ForEach @(
            @{ splat = @{ List=$true                } }
            @{ splat = @{ List=$true; Refresh=$true } }
        ) {
            $orders = Get-PAOrder @splat

            $orders                         | Should -Not -BeNullOrEmpty
            $orders.Count                   | Should -Be 3
            'PoshACME.PAOrder' | Should -BeIn $orders[0].PSObject.TypeNames
            'PoshACME.PAOrder' | Should -BeIn $orders[1].PSObject.TypeNames
            'PoshACME.PAOrder' | Should -BeIn $orders[2].PSObject.TypeNames

            if ($splat.Refresh) {
                Should -Invoke Update-PAOrder -Exactly 3 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Update-PAOrder -ModuleName Posh-ACME
            }
        }

    }

}
