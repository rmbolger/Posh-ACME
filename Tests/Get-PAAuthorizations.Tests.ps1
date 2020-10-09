BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
}

Describe "Get-PAAuthorizations" {

    BeforeAll {
        $fakeAcct = Get-Content "$PSScriptRoot\TestFiles\fakeAccount1.json" -Raw | ConvertFrom-Json
        $fakeAcct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
        Mock -ModuleName Posh-ACME Get-PAAccount { return $fakeAcct }
    }

    Context "No expires property in authz response" {
        It "Does not throw" {
            $fakeAuthzNoExpires = @{
                identifier = @{ type='dns'; value='example.com' }
                status = 'pending'
                challenges = @(
                    @{ type='http-01'; status='pending'; url='https://acme.example.com/chal/1' }
                    @{ type='dns-01'; status='pending'; url='https://acme.example.com/chal/2' }
                    @{ type='tls-alpn-01'; status='pending'; url='https://acme.example.com/chal/3' }
                )
            } | ConvertTo-Json -Depth 5
            Mock -ModuleName Posh-ACME Invoke-ACME { [pscustomobject]@{ Content = $fakeAuthzNoExpires } }

            InModuleScope Posh-ACME {
                { Get-PAAuthorizations 'https://acme.example.com/authz/1' } | Should -Not -Throw
            }
        }
    }

    Context "No status property in authz challenges" {
        It "Handles gracefully" {

            $fakeAuthzNoChallengeStatus = @{
                identifier = @{ type='dns'; value='example.com' }
                status = 'pending'
                expires = '2050-09-09T15:43:33Z'
                challenges = @(
                    @{ type='http-01'; url='https://acme.example.com/chal/1' }
                    @{ type='dns-01'; url='https://acme.example.com/chal/2' }
                    @{ type='tls-alpn-01'; url='https://acme.example.com/chal/3' }
                )
            } | ConvertTo-Json -Depth 5

            Mock -ModuleName Posh-ACME Invoke-ACME { return [pscustomobject]@{ Content = $fakeAuthzNoChallengeStatus } }
            Mock -ModuleName Posh-ACME Write-Warning {}

            InModuleScope Posh-ACME {
                { Get-PAAuthorizations 'https://acme.example.com/authz/1' } | Should -Not -Throw

                Should -Invoke Write-Warning

                $auth = Get-PAAuthorizations 'https://acme.example.com/authz/1'

                $auth.challenges[0].status | Should -Be 'pending'
                $auth.challenges[1].status | Should -Be 'pending'
                $auth.challenges[2].status | Should -Be 'pending'
            }
        }
    }

}
