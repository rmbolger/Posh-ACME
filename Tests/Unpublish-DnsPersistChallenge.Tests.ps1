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
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { [pscustomobject]@{ HashedAccountUri = 'https://ca.example/hash/shared' } }
        $output = Unpublish-DnsPersistChallenge -Domain 'example.com' -Account $account `
            -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -NoDomainCorrelationMitigation -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq 'example.com' -and $NoDomainCorrelationMitigation }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Uses the domain-correlation opt-out with explicit account details when removing" {
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { [pscustomobject]@{ HashedAccountUri = 'https://ca.example/hash/shared' } }
        $output = Unpublish-DnsPersistChallenge -Domain 'www.example.com' `
            -AccountUri 'https://ca.example/acct/123' -KeyThumbprint 'thumbprint' `
            -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -NoDomainCorrelationMitigation -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq 'www.example.com' -and $NoDomainCorrelationMitigation }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.www\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Uses the domain-correlation opt-out for order challenges when removing" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            [pscustomobject]@{
                fqdn = 'order.example.com'
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
            }
        }
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { [pscustomobject]@{ HashedAccountUri = 'https://ca.example/hash/shared' } }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Unpublish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs -NoDomainCorrelationMitigation 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq 'order.example.com' -and $NoDomainCorrelationMitigation }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.order\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Rejects the domain-correlation switch with a caller-supplied hashed URI" {
        {
            Unpublish-DnsPersistChallenge -Domain 'example.com' -HashedAccountUri 'https://ca.example/hash/external' `
                -IssuerDomainName 'authority.example' -NoDomainCorrelationMitigation -Plugin Manual
        } | Should -Throw
    }

    It "Unpublishes normalized owners with a shared opt-out hash from the helper" {
        $records = @('example.com','*.other.example.com') | Get-DnsPersistAccountUri `
            -Account $account -AccountHashPrefix $prefix -NoDomainCorrelationMitigation
        $output = $records | Unpublish-DnsPersistChallenge -IssuerDomainName 'authority.example' `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        $compact = $output -replace '\s+', ''
        $uri = $records[0].HashedAccountUri
        $compact | Should -Match ([regex]::Escape("_validation-persist.example.com->`"authority.example;accounturi=$uri`""))
        $compact | Should -Match ([regex]::Escape("_validation-persist.other.example.com->`"authority.example;accounturi=$uri;policy=wildcard`""))
    }

    It "Unpublishes every cached challenge piped from Get-PublishedPersistChallenge" {
        @(
            [pscustomobject]@{
                fqdn = 'first.example.com'; issuer = 'authority.example'
                hashAcctUri = 'https://ca.example/hash/first'; addWildcard = $true
                persistUntil = '1806537600'; fromAcctUri = ''; fromAcctThumb = ''
            }
            [pscustomobject]@{
                fqdn = 'first.example.com'; issuer = 'authority.example'
                hashAcctUri = 'https://ca.example/hash/first'; addWildcard = $true
                persistUntil = '1806537600'; fromAcctUri = ''; fromAcctThumb = ''
            }
            [pscustomobject]@{
                fqdn = 'first.example.com'; issuer = 'authority.example'
                hashAcctUri = 'https://ca.example/hash/first'; addWildcard = $false
                persistUntil = '1806537600'; fromAcctUri = ''; fromAcctThumb = ''
            }
            [pscustomobject]@{
                fqdn = 'second.example.com'; issuer = 'other.example'
                hashAcctUri = 'https://ca.example/hash/second'; addWildcard = $false
                persistUntil = $null; fromAcctUri = ''; fromAcctThumb = ''
            }
        ) | ConvertTo-Json -Depth 5 | Set-Content 'TestDrive:\PersistedChallenges.json'

        $output = Get-PublishedPersistChallenge | Unpublish-DnsPersistChallenge `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ([regex]::Matches($output, '_validation-persist\.first\.example\.com ->')).Count | Should -Be 3
        ([regex]::Matches($output, '_validation-persist\.second\.example\.com ->')).Count | Should -Be 1
        ([regex]::Matches($output, 'policy=wildcard')).Count | Should -Be 2
        ($output -replace '\s+', '') | Should -Match ([regex]::Escape('_validation-persist.first.example.com->"authority.example;accounturi=https://ca.example/hash/first;policy=wildcard;persistUntil=1806537600"'))
        ($output -replace '\s+', '') | Should -Match ([regex]::Escape('_validation-persist.first.example.com->"authority.example;accounturi=https://ca.example/hash/first;persistUntil=1806537600"'))
        ($output -replace '\s+', '') | Should -Match ([regex]::Escape('_validation-persist.second.example.com->"other.example;accounturi=https://ca.example/hash/second"'))

        $remaining = Get-Content 'TestDrive:\PersistedChallenges.json' -Raw | ConvertFrom-Json
        @($remaining) | Should -HaveCount 0
    }

    It "Removes matching cached entries without removing other challenge variants" {
        $cachePath = 'TestDrive:\PersistedChallenges.json'
        $record = [pscustomobject]@{
            fqdn = 'example.com'; issuer = 'authority.example'
            hashAcctUri = 'https://ca.example/hash/first'; addWildcard = $false
            persistUntil = $null; fromAcctUri = ''; fromAcctThumb = ''
        }
        @(
            $record
            $record
            [pscustomobject]@{ fqdn='example.com'; issuer='authority.example'; hashAcctUri='https://ca.example/hash/first'; addWildcard=$true; persistUntil=$null }
            [pscustomobject]@{ fqdn='example.com'; issuer='authority.example'; hashAcctUri='https://ca.example/hash/second'; addWildcard=$false; persistUntil=$null }
            [pscustomobject]@{ fqdn='example.com'; issuer='authority.example'; hashAcctUri='https://ca.example/hash/first'; addWildcard=$false; persistUntil='1806537600' }
            [pscustomobject]@{ fqdn='example.com'; issuer='other.example'; hashAcctUri='https://ca.example/hash/first'; addWildcard=$false; persistUntil=$null }
            [pscustomobject]@{ fqdn='other.example.com'; issuer='authority.example'; hashAcctUri='https://ca.example/hash/first'; addWildcard=$false; persistUntil=$null }
        ) | ConvertTo-Json -Depth 5 | Set-Content $cachePath

        Unpublish-DnsPersistChallenge -Domain 'example.com' -HashedAccountUri 'https://ca.example/hash/first' `
            -IssuerDomainName 'authority.example' -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-Null

        $remaining = Get-Content $cachePath -Raw | ConvertFrom-Json
        @($remaining) | Should -HaveCount 5
        @($remaining | Where-Object addWildcard -eq $true) | Should -HaveCount 1
        @($remaining | Where-Object hashAcctUri -eq 'https://ca.example/hash/second') | Should -HaveCount 1
        @($remaining | Where-Object persistUntil -eq '1806537600') | Should -HaveCount 1
        @($remaining | Where-Object issuer -eq 'other.example') | Should -HaveCount 1
        @($remaining | Where-Object fqdn -eq 'other.example.com') | Should -HaveCount 1
    }

    It "Does not create a cache when no published challenges were cached" {
        $cachePath = 'TestDrive:\PersistedChallenges.json'
        Remove-Item $cachePath -ErrorAction Ignore

        Unpublish-DnsPersistChallenge -Domain 'example.com' -HashedAccountUri 'https://ca.example/hash/first' `
            -IssuerDomainName 'authority.example' -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-Null

        $cachePath | Should -Not -Exist
    }
}
