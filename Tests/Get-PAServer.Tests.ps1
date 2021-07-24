Describe "Get-PAServer" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "Empty Config" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Write-Warning {}
            Mock -ModuleName Posh-ACME Set-PAServer {}
        }

        It "Returns No Current or List Results" -ForEach @(
            @{ splat = @{                           } }
            @{ splat = @{             Refresh=$true } }
            @{ splat = @{ List=$true                } }
            @{ splat = @{ List=$true; Refresh=$true } }
        ) {
            Get-PAServer @splat | Should -BeNullOrEmpty
            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME
            Should -Not -Invoke Set-PAServer -ModuleName Posh-ACME
        }

        It "Returns No Results for Specific Server" -ForEach @(
            @{ splat = @{ DirectoryUrl='LE_STAGE'                                                             } }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'                                          } }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'; Name='srvr1'                            } }
            @{ splat = @{                                             Name='srvr1'                            } }
            @{ splat = @{ DirectoryUrl='LE_STAGE';                                  Quiet=$true               } }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory';               Quiet=$true               } }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'; Name='srvr1'; Quiet=$true               } }
            @{ splat = @{                                             Name='srvr1'; Quiet=$true               } }
            @{ splat = @{ DirectoryUrl='LE_STAGE';                                              Refresh=$true } }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory';                           Refresh=$true } }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'; Name='srvr1';             Refresh=$true } }
            @{ splat = @{                                             Name='srvr1';             Refresh=$true } }
        ) {
            Get-PAServer @splat | Should -BeNullOrEmpty
            if ($splat.Quiet) {
                Should -Not -Invoke Write-Warning -ModuleName Posh-ACME
            } else {
                Should -Invoke Write-Warning -Exactly 1 -ModuleName Posh-ACME
            }
            Should -Not -Invoke Set-PAServer -ModuleName Posh-ACME
        }
    }

    Context "Test Config" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse

            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Write-Warning {}
            Mock -ModuleName Posh-ACME Set-PAServer {}
        }

        It "Returns Current Server" -ForEach @(
            @{ splat = @{               } }
            @{ splat = @{ Refresh=$true } }
        ) {
            $dir = Get-PAServer @splat

            $dir                       | Should -Not -BeNullOrEmpty
            $dir.PSObject.TypeNames[0] | Should -Be 'PoshACME.PAServer'
            $dir.Name                  | Should -Be 'srvr1'
            $dir.Folder                | Should -Be (Join-Path $TestDrive 'srvr1')
            $dir.location              | Should -Be 'https://acme.test/directory'
            $dir.SkipCertificateCheck  | Should -BeFalse
            $dir.DisableTelemetry      | Should -BeFalse

            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME
            if ($splat.Refresh) {
                Should -Invoke Set-PAServer -Exactly 1 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Set-PAServer -ModuleName Posh-ACME
            }
        }

        It "Returns Server List" -ForEach @(
            @{ splat = @{ List=$true;               } }
            @{ splat = @{ List=$true; Refresh=$true } }
        ) {
            $dirs = Get-PAServer @splat

            $dirs                          | Should -Not -BeNullOrEmpty
            $dirs.Count                    | Should -Be 3
            $dirs[0].PSObject.TypeNames[0] | Should -Be 'PoshACME.PAServer'

            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME
            if ($splat.Refresh) {
                Should -Invoke Set-PAServer -Exactly 3 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Set-PAServer -ModuleName Posh-ACME
            }
        }

        It "Returns Specific Server" -ForEach @(
            @{ splat = @{ DirectoryUrl='LE_STAGE'                                                 }; Name='le-stage' }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'                              }; Name='srvr1'    }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'; Name='srvr1'                }; Name='srvr1'    }
            @{ splat = @{                                             Name='srvr1'                }; Name='srvr1'    }
            @{ splat = @{ DirectoryUrl='LE_STAGE';                                  Refresh=$true }; Name='le-stage' }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory';               Refresh=$true }; Name='srvr1'    }
            @{ splat = @{ DirectoryUrl='https://acme.test/directory'; Name='srvr1'; Refresh=$true }; Name='srvr1'    }
            @{ splat = @{                                             Name='srvr1'; Refresh=$true }; Name='srvr1'    }
            @{ splat = @{ DirectoryUrl='https://acme2.test/directory'                             }; Name='srvr2'    }
            @{ splat = @{                                             Name='srvr2';               }; Name='srvr2'    }
        ) {
            $dir = Get-PAServer @splat

            $dir                       | Should -Not -BeNullOrEmpty
            $dir.PSObject.TypeNames[0] | Should -Be 'PoshACME.PAServer'
            $dir.Name                  | Should -Be $Name
            $dir.Folder                | Should -Be (Join-Path $TestDrive $Name)

            Should -Not -Invoke Write-Warning -ModuleName Posh-ACME
            if ($splat.Refresh) {
                Should -Invoke Set-PAServer -Exactly 1 -ModuleName Posh-ACME
            } else {
                Should -Not -Invoke Set-PAServer -ModuleName Posh-ACME
            }

            # make sure flag values are true on srvr2
            if ($Name -eq 'srvr2') {
                $dir.SkipCertificateCheck | Should -BeTrue
                $dir.DisableTelemetry     | Should -BeTrue
            }

        }

    }

}
