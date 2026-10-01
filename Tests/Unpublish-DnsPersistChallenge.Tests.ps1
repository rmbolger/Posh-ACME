Describe "Unpublish-DnsPersistChallenge" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        InModuleScope Posh-ACME { Import-PAConfig -NoRefresh }

        $account = Get-PAAccount -ID acct1
        $prefix = 'https://ca.example/account-hash/'
        $pluginArgs = @{ ManualNonInteractive = $true }
    }

    It "Uses the domain-correlation opt-out when removing an account object's record" {
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { 'https://ca.example/hash/shared' }
        $output = Unpublish-DnsPersistChallenge -Domain 'example.com' -Account $account `
            -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -NoDomainCorrelationMitigation -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq '*' }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Uses the domain-correlation opt-out with explicit account details when removing" {
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { 'https://ca.example/hash/shared' }
        $output = Unpublish-DnsPersistChallenge -Domain 'www.example.com' `
            -AccountUri 'https://ca.example/acct/123' -KeyThumbprint 'thumbprint' `
            -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -NoDomainCorrelationMitigation -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq '*' }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.www\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Uses the domain-correlation opt-out for order challenges when removing" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            [pscustomobject]@{
                fqdn = 'order.example.com'
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
            }
        }
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { 'https://ca.example/hash/shared' }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Unpublish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs -NoDomainCorrelationMitigation 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq '*' }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.order\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Rejects the domain-correlation switch with a caller-supplied hashed URI" {
        {
            Unpublish-DnsPersistChallenge -Domain 'example.com' -HashedAccountUri 'https://ca.example/hash/external' `
                -IssuerDomainName 'authority.example' -NoDomainCorrelationMitigation -Plugin Manual
        } | Should -Throw
    }
}
