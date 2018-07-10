. $PSScriptRoot\..\Posh-ACME\DnsPlugins\Azure.ps1

Describe "Connect-AZTenant" {

    $fakeTokenResponse = [pscustomobject]@{
        expires_on   = '1530691200' # 2018-07-04 08:00:00 UTC
        access_token = 'faketoken'
    }

    $script:UseBasic = @{}

    Mock -CommandName Invoke-RestMethod -MockWith { return $fakeTokenResponse }
    Mock -CommandName ConvertFrom-AccessToken -MockWith { return $fakeTokenResponse }
    Mock -CommandName Get-Date -ParameterFilter { -not $Date } -MockWith {
        return (Get-Date '2018-07-04T09:00:00Z') # 2018-07-04 09:00 UTC
    }

    $fakeGoodToken = [pscustomobject]@{
        Expires    = (Get-UtcDate '2018-07-04T09:05:00Z') # just after mocked Get-Date
        AuthHeader = @{ Authorization = 'Bearer fakegoodtoken' }
    }

    $fakeExpiredToken = [pscustomobject]@{
        Expires    = (Get-UtcDate '2018-07-04T08:55:00Z') # just before mocked Get-Date
        AuthHeader = @{ Authorization = 'Bearer fakeexpiredtoken' }
    }


    Context "Credential param set" {

        $fakeTenant = '00000000-0000-0000-0000-000000000000'
        $fakePass = "fakepass" | ConvertTo-SecureString -AsPlainText -Force
        $fakeCred = New-Object System.Management.Automation.PSCredential('fakeuser', $fakePass)

        It "calls Invoke-RestMethod if no existing token" {
            $script:AZToken = $null
            Connect-AZTenant $fakeTenant $fakeCred
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "calls Invoke-RestMethod if token expired" {
            $script:AZToken = $fakeExpiredToken
            Connect-AZTenant $fakeTenant $fakeCred
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "sets new AZToken if token expired" {
            $script:AZToken | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer faketoken'
            $script:AZToken.Expires | Should -Be (Get-UtcDate '2018-07-04T07:55:00Z')
        }
        It "calls nothing if current token is valid" {
            $script:AZToken = $fakeGoodToken
            Connect-AZTenant $fakeTenant $fakeCred
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "does not overwrite existing token if current token is valid" {
            $script:AZToken | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer fakegoodtoken'
            $script:AZToken.Expires | Should -Be (Get-UtcDate '2018-07-04T09:05:00Z')
        }

    }

    Context "Token param set" {

        $fakeAccessToken = 'blah.blah.blah'

        It "calls ConvertFrom-AccessToken if no existing token" {
            $script:AZToken = $null
            Connect-AZTenant -AZAccessToken $fakeAccessToken
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 1 -Exactly -Scope It
        }
        It "calls ConvertFrom-AccessToken if token expired" {
            $script:AZToken = $fakeExpiredToken
            Connect-AZTenant -AZAccessToken $fakeAccessToken
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 1 -Exactly -Scope It
        }
        It "uses passed in token if AZToken expired" {
            $script:AZToken | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer faketoken'
            $script:AZToken.Expires | Should -Be (Get-UtcDate '2018-07-04T07:55:00Z')
        }
        It "calls nothing if current token is valid" {
            $script:AZToken = $fakeGoodToken
            Connect-AZTenant -AZAccessToken $fakeAccessToken
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "does not overwrite existing token if current token is valid" {
            $script:AZToken | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer fakegoodtoken'
            $script:AZToken.Expires | Should -Be (Get-UtcDate '2018-07-04T09:05:00Z')
        }

    }

    Context "IMDS param set" {

        It "calls Invoke-RestMethod if no existing token" {
            $script:AZToken = $null
            Connect-AZTenant -AZUseIMDS
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "calls Invoke-RestMethod if token expired" {
            $script:AZToken = $fakeExpiredToken
            Connect-AZTenant -AZUseIMDS
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "sets new AZToken if token expired" {
            $script:AZToken | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer faketoken'
            $script:AZToken.Expires | Should -Be (Get-UtcDate '2018-07-04T07:55:00Z')
        }
        It "calls nothing if current token is valid" {
            $script:AZToken = $fakeGoodToken
            Connect-AZTenant -AZUseIMDS
            Assert-MockCalled -CommandName Invoke-RestMethod -Times 0 -Exactly -Scope It
            Assert-MockCalled -CommandName ConvertFrom-AccessToken -Times 0 -Exactly -Scope It
        }
        It "does not overwrite existing token if current token is valid" {
            $script:AZToken | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader | Should -Not -BeNullOrEmpty
            $script:AZToken.AuthHeader.Authorization | Should -BeExactly 'Bearer fakegoodtoken'
            $script:AZToken.Expires | Should -Be (Get-UtcDate '2018-07-04T09:05:00Z')
        }

    }

}


Describe "Get-UtcDate" {
    $testDate = "January 1, 1970 4:45:00 GMT"
    $stringResult = 'Thursday, January 1, 1970 4:45:00 AM'

    $testResult = Get-UtcDate -Date $testDate

    it "returns a DateTime object" {
        $testResult | Should -BeOfType [DateTime]
    }

    it "returns an object with the Kind property of 'UTC'" {
        $testResult.Kind | Should -Be 'UTC'
    }

    it "returns an object with a Date property of '$stringResult'" {
        $testResult.DateTime | Should -Be $stringResult
    }
}

Describe "Get-Epoch" {
    $stringResult = "Thursday, January 1, 1970 12:00:00 AM"
    $testResult = Get-Epoch

    it "returns a DateTime object" {
        $testResult | Should -BeOfType [DateTime]
    }

    it "returns an object with the Kind property of 'UTC'" {
        $testResult.Kind | Should -Be 'UTC'
    }

    it "returns an object with a Date property of '$stringResult'" {
        $testResult.DateTime | Should -Be $stringResult
    }
}