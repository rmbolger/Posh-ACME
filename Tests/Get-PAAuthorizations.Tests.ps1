Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "Get-PAAuthorizations" {

    InModuleScope Posh-ACME {

        $fakeAcct = Get-ChildItem "$PSScriptRoot\TestFiles\fakeAccount.json" | Get-Content -Raw | ConvertFrom-Json
        $fakeAcct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
        Mock Get-PAAccount { return $fakeAcct }

        Context "No expires property in authz response" {

            $fakeAuthzNoExpires = @{
                identifier = @{ type='dns'; value='example.com' }
                status = 'pending'
                challenges = @(
                    @{ type='http-01'; status='pending'; url='https://acme.example.com/chal/1' }
                    @{ type='dns-01'; status='pending'; url='https://acme.example.com/chal/2' }
                    @{ type='tls-alpn-01'; status='pending'; url='https://acme.example.com/chal/3' }
                )
            } | ConvertTo-Json -Depth 5

            $fakeResponse = [pscustomobject]@{ Content = $fakeAuthzNoExpires }

            Mock Invoke-ACME { return $fakeResponse }

            It "Does not throw an error" {
                { Get-PAAuthorizations 'https://acme.example.com/authz/1' } | Should -Not -Throw
            }

        }

        Context "No status property in authz challenges" {

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

            $fakeResponse = [pscustomobject]@{ Content = $fakeAuthzNoChallengeStatus }

            Mock Invoke-ACME { return $fakeResponse }
            Mock Write-Warning { }

            It "Does not throw an error" {
                { Get-PAAuthorizations 'https://acme.example.com/authz/1' } | Should -Not -Throw
            }
            It "Warns about the problem" {
                Assert-MockCalled Write-Warning
            }
            It "Adds challenge statuses to match parent status" {
                $auth = Get-PAAuthorizations 'https://acme.example.com/authz/1'
                $auth.challenges[0].status | Should -Be 'pending'
                $auth.challenges[1].status | Should -Be 'pending'
                $auth.challenges[2].status | Should -Be 'pending'
            }

        }

    }
}
