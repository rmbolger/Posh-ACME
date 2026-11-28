Describe "Set-PAServer" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force

        # whether the module is currently skipping cert validation, on either edition
        function Get-SkipState {
            InModuleScope Posh-ACME {
                if ($script:SkipCertSupported) {
                    [bool]$script:UseBasic.SkipCertificateCheck
                } else {
                    [bool][Net.ServicePointManager]::ServerCertificateValidationCallback
                }
            }
        }
    }

    Context "Directory request fails" {

        BeforeEach {
            # srvr1 is the current server and does not skip cert validation
            InModuleScope Posh-ACME { Import-PAConfig -Level Server -NoRefresh }
            Mock -ModuleName Posh-ACME Write-Debug {}
        }

        It "Restores cert validation when the request throws" {
            Mock -ModuleName Posh-ACME Invoke-WebRequest { throw 'Connection refused' }

            { Set-PAServer -DirectoryUrl 'https://acme3.test/directory' -SkipCertificateCheck } | Should -Throw
            (Get-PAServer).Name | Should -Be 'srvr1'
            Get-SkipState | Should -BeFalse
        }

        It "Restores cert validation when the response is not JSON" {
            Mock -ModuleName Posh-ACME Invoke-WebRequest { [pscustomobject]@{ Content = '<html>'; Headers = @{} } }

            { Set-PAServer -DirectoryUrl 'https://acme3.test/directory' -SkipCertificateCheck } | Should -Throw
            (Get-PAServer).Name | Should -Be 'srvr1'
            Get-SkipState | Should -BeFalse
        }

        It "Restores cert validation when refreshing a list that includes an unreachable skip server" {
            # srvr2 skips cert validation and is the only one that fails
            Mock -ModuleName Posh-ACME Invoke-WebRequest {
                if ($Uri -eq 'https://acme2.test/directory') { throw 'Connection refused' }
                [pscustomobject]@{
                    Content = '{"newAccount":"a","newOrder":"o","newNonce":"n","keyChange":"k","revokeCert":"r"}'
                    Headers = @{ 'Replay-Nonce' = 'nonce' }
                }
            }

            { Get-PAServer -List -Refresh } | Should -Throw
            (Get-PAServer).Name | Should -Be 'srvr1'
            Get-SkipState | Should -BeFalse
        }
    }

    Context "Directory request for a different server" {

        BeforeAll {
            Mock -ModuleName Posh-ACME Write-Debug {}
            Mock -ModuleName Posh-ACME Write-Host {}
            # remember whether cert validation was being skipped when the request was made
            Mock -ModuleName Posh-ACME Invoke-WebRequest {
                $script:skipAtRequest = Get-SkipState
                [pscustomobject]@{
                    Content = '{"newAccount":"a","newOrder":"o","newNonce":"n","keyChange":"k","revokeCert":"r"}'
                    Headers = @{ 'Replay-Nonce' = 'nonce' }
                }
            }
        }

        AfterAll {
            Set-PAServer -Name srvr1 -NoRefresh
        }

        # srvr1 does not skip cert validation and srvr2 does
        It "Uses the <Desc> setting when switching from <From>" -TestCases @(
            @{ From='srvr1'; To=@{Name='srvr2'};                                 Skip=$true;  Desc="saved server's" }
            @{ From='srvr2'; To=@{Name='srvr1'};                                 Skip=$false; Desc="saved server's" }
            @{ From='srvr2'; To=@{DirectoryUrl='https://acme3.test/directory'}; Skip=$false; Desc='default' }
        ) {
            Set-PAServer -Name $From -NoRefresh
            $script:skipAtRequest = $null

            Set-PAServer @To
            $script:skipAtRequest | Should -Be $Skip
            Get-SkipState | Should -Be $Skip
        }
    }
}
