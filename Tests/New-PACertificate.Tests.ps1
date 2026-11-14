Describe "New-PACertificate" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "Debug output" {

        BeforeAll {
            InModuleScope Posh-ACME { Import-PAConfig }
            Mock -ModuleName Posh-ACME Update-PAOrder {}
            # stop as soon as the order would be created or changed
            Mock -ModuleName Posh-ACME New-PAOrder { throw 'stop' }
            Mock -ModuleName Posh-ACME Set-PAOrder { throw 'stop' }
        }

        It "Doesn't write plugin arg values when <Case>" -TestCases @(
            @{ Case = 'creating an order'; Status = 'invalid'; RenewAfter = $null;                  Message = 'New order params' }
            @{ Case = 'reusing an order';  Status = 'valid';   RenewAfter = '2099-01-01T00:00:00Z'; Message = 'Set order params' }
        ) {
            $orderFile = Join-Path $TestDrive 'srvr1\acct1\example.com\order.json'
            $order = Get-Content $orderFile -Raw | ConvertFrom-Json
            $order.status = $Status
            $order.RenewAfter = $RenewAfter
            $order | ConvertTo-Json -Depth 5 | Out-File $orderFile

            # debug preference only reaches module functions when it's set inside the module
            $log = InModuleScope Posh-ACME {
                $DebugPreference = 'Continue'
                & {
                    try { New-PACertificate 'example.com' -Plugin Route53 -PluginArgs @{ R53SecretKeyInsecure = 'Hunter2Sentinel' } }
                    catch { "CAUGHT: $_" }
                } 5>&1 | Out-String
            }
            $log | Should -Match $Message
            $log | Should -Not -Match 'Hunter2Sentinel'
        }
    }
}
