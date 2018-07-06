. $PSScriptRoot\..\Posh-ACME\DnsPlugins\Azure.ps1

Describe "Connect-AZTenant" {
    Mock -CommandName Invoke-RestMethod -MockWith { return $true }

    $script:UseBasic = @{}
    $currentTime = Get-Date
    $tokenExpiration = [System.Convert]::ToUInt32( ( ( Get-Date '1/1/1970' ) - $currentTime.AddHours(1).ToUniversalTime() ).TotalSeconds * -1 )
    $goodAZToken = [pscustomobject]@{
        Expires = (Get-Date '1/1/1970').AddSeconds($tokenExpiration - 300)
        AuthHeader = @{ Authorization = "Bearer SOMETOKENVALUE" }
    }

    It "generates a new token if one is not already present" {
        $script:AZToken = $null
        Connect-AZTenant -AZUseIMDS
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly -Scope It
    }

    It "does nothing if the current token is valid" {
        $script:AZToken = $goodAZToken
        Connect-AZTenant -AZUseIMDS
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 0 -Exactly -Scope It
    }

    It "generates a new token if the current token has expired" {
        Mock -CommandName Get-Date -MockWith { return $currentTime.AddHours(2) }
        $script:AZToken = $goodAZToken
        Connect-AZTenant -AZUseIMDS
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 1 -Exactly -Scope It
    }
}