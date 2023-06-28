Describe "Connect-AZTenant" {

    BeforeAll {

        . (Join-Path $PSScriptRoot "..\Posh-ACME\Plugins\Azure.ps1")
        . (Join-Path $PSScriptRoot "..\Posh-ACME\Private\MockWrappers.ps1")
        . (Join-Path $PSScriptRoot "..\Posh-ACME\Private\ConvertTo-Base64Url.ps1")
        $script:UseBasic = @{UseBasicParsing = $true}

        $fakeTokenText = [ordered]@{
            aud = 'https://management.core.windows.net/'
            exp = [DateTimeOffset]::Parse('2018-07-04T10:00:00Z').ToUnixTimeSeconds() # 1530698400
            tid = '00000000-0000-0000-0000-000000000000'
        } | ConvertTo-Json | ConvertTo-Base64Url

        $fakeTokenResponse = [pscustomobject]@{
            expires_on   = [DateTimeOffset]::Parse('2018-07-04T10:00:00Z').ToUnixTimeSeconds() # 1530698400
            access_token = $fakeTokenText
            tenant = '00000000-0000-0000-0000-000000000000'
        }

        Mock Invoke-RestMethod { return $fakeTokenResponse }
        Mock ConvertFrom-AccessToken { return $fakeTokenResponse }
        Mock Get-DateTimeOffsetNow { return [DateTimeOffset]::Parse('2018-07-04T09:00:00Z') }

    }

    Context "Token param set" {

        BeforeAll {
            $fakeAccessToken = "blah.$fakeTokenText.blah"
            $mockedBearer = "Bearer $fakeTokenText"
        }

        It "Uses the token as-is" -TestCases @(
            @{ curToken = $null }
            @{ curToken = [pscustomobject]@{
                Expires    = [DateTimeOffset]::Parse('2018-07-04T06:00:00Z') # expired before mocked "Now"
                AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
                Tenant     = '11111111-1111-1111-1111-111111111111'
            }}
        ) {
            # setup an expired cached token
            $script:AZToken = $curToken

            Connect-AZTenant -AZAccessToken $fakeAccessToken

            Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            Should -Invoke ConvertFrom-AccessToken -Times 1 -Exactly -Scope It

            $script:AZToken.Tenant | Should -Be '00000000-0000-0000-0000-000000000000'
            $script:AZToken.Expires | Should -Be ([DateTimeOffset]::Parse('2018-07-04T09:55:00Z')) # 5 min prior to actual
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly $mockedBearer
        }
    }

    Context "IMDS param set" {

        BeforeAll {
            $mockedBearer = "Bearer $fakeTokenText"
        }

        It "Gets new token if no current or expired" -TestCases @(
            @{ curToken = $null }
            @{ curToken = [pscustomobject]@{
                Expires = [DateTimeOffset]::Parse('2018-07-04T06:00:00Z')
                AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
                Tenant     = '00000000-0000-0000-0000-000000000000'
            }}
        ) {
            $script:AZToken = $curToken

            Connect-AZTenant -AZUseIMDS

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                $Uri -eq 'http://169.254.169.254/metadata/identity/oauth2/token'
            }
            Should -Invoke ConvertFrom-AccessToken -Times 1 -Exactly -Scope It

            $script:AZToken.Tenant | Should -Be '00000000-0000-0000-0000-000000000000'
            $script:AZToken.Expires | Should -Be ([DateTimeOffset]::Parse('2018-07-04T09:55:00Z')) # 5 min prior to actual
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly $mockedBearer
        }

        It "Uses existing token if still valid" {
            $script:AZToken = [pscustomobject]@{
                Expires = [DateTimeOffset]::Parse('2018-07-04T10:00:00Z')
                AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
                Tenant     = '00000000-0000-0000-0000-000000000000'
            }

            Connect-AZTenant -AZUseIMDS

            Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            Should -Invoke ConvertFrom-AccessToken -Times 0 -Exactly -Scope It

            $script:AZToken.Tenant | Should -Be '00000000-0000-0000-0000-000000000000'
            $script:AZToken.Expires | Should -Be ([DateTimeOffset]::Parse('2018-07-04T10:00:00Z'))
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer fakeexpiredtoken'
        }

    }

    Context "Credential param set" {

        BeforeAll {
            $mockedBearer = "Bearer $fakeTokenText"
            $fakeTenant = '00000000-0000-0000-0000-000000000000'
            $fakePass = "fake+p&ss" | ConvertTo-SecureString -AsPlainText -Force
            $fakeCred = New-Object System.Management.Automation.PSCredential('fake user', $fakePass)
        }

        It "Gets new token if no current, expired current, or new tenant" -TestCases @(
            @{ curToken = $null }
            @{ curToken = [pscustomobject]@{
                Expires = [DateTimeOffset]::Parse('2018-07-04T06:00:00Z')
                AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
                Tenant     = '00000000-0000-0000-0000-000000000000'
            }}
            @{ curToken = [pscustomobject]@{
                Expires = [DateTimeOffset]::Parse('2018-07-04T10:00:00Z')
                AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
                Tenant     = '11111111-1111-1111-1111-111111111111'
            }}
        ) {
            $script:AZToken = $null

            Connect-AZTenant -AZTenantId $fakeTenant -AZAppCred $fakeCred

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                $Body -match "[&?]client_id=fake%20user(&|$)" -and $Body -match "[&?]client_secret=fake%2[Bb]p%26ss(&|$)"
            }
            Should -Invoke ConvertFrom-AccessToken -Times 1 -Exactly -Scope It

            $script:AZToken.Tenant | Should -Be '00000000-0000-0000-0000-000000000000'
            $script:AZToken.Expires | Should -Be ([DateTimeOffset]::Parse('2018-07-04T09:55:00Z')) # 5 min prior to actual
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly $mockedBearer
        }

        It "Uses existing token if still valid" {
            $script:AZToken = [pscustomobject]@{
                Expires = [DateTimeOffset]::Parse('2018-07-04T10:00:00Z')
                AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
                Tenant     = '00000000-0000-0000-0000-000000000000'
            }

            Connect-AZTenant -AZTenantId $fakeTenant -AZAppCred $fakeCred

            Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            Should -Invoke ConvertFrom-AccessToken -Times 0 -Exactly -Scope It

            $script:AZToken.Tenant | Should -Be '00000000-0000-0000-0000-000000000000'
            $script:AZToken.Expires | Should -Be ([DateTimeOffset]::Parse('2018-07-04T10:00:00Z'))
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer fakeexpiredtoken'
        }

    }

}
