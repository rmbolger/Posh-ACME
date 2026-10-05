Describe "Publish-DnsPersistChallenge" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        InModuleScope Posh-ACME { Import-PAConfig -NoRefresh }

        $unicodeDomain = [string]::Concat('b', [char]0x00FC, 'cher.de.')
        $account = Get-PAAccount -ID acct1
        $prefix = 'https://ca.example/account-hash/'
        $pluginArgs = @{ ManualNonInteractive = $true }
    }

    It "Uses the A-label for an account object's record owner and hash" {
        $expectedUri = Get-DnsPersistAccountUri -Domain 'xn--bcher-kva.de' -Account $account -AccountHashPrefix $prefix
        $output = Publish-DnsPersistChallenge -Domain $unicodeDomain -Account $account -AccountHashPrefix $prefix `
            -IssuerDomainName 'authority.example' -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ($output -replace '\s+', '') | Should -Match ([regex]::Escape("_validation-persist.xn--bcher-kva.de->`"authority.example;accounturi=$expectedUri`""))
    }

    It "Uses the A-label for explicit account details and wildcard policy" {
        $accountUri = 'https://ca.example/acct/123'
        $thumbprint = 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs'
        $expectedUri = Get-DnsPersistAccountUri -Domain 'xn--bcher-kva.de' -AccountUri $accountUri `
            -KeyThumbprint $thumbprint -AccountHashPrefix $prefix
        $output = Publish-DnsPersistChallenge -Domain "*.$unicodeDomain" -AccountUri $accountUri `
            -KeyThumbprint $thumbprint -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ($output -replace '\s+', '') | Should -Match ([regex]::Escape("_validation-persist.xn--bcher-kva.de->`"authority.example;accounturi=$expectedUri;policy=wildcard`""))
    }

    It "Normalizes an advanced record owner without changing its supplied hash" {
        $hashedUri = 'https://ca.example/account-hash/sha-256/external'
        $output = Publish-DnsPersistChallenge -Domain $unicodeDomain -HashedAccountUri $hashedUri `
            -IssuerDomainName 'authority.example' -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ($output -replace '\s+', '') | Should -Match ([regex]::Escape("_validation-persist.xn--bcher-kva.de->`"authority.example;accounturi=$hashedUri`""))
    }

    It "Normalizes order authorization names before publishing" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            [pscustomobject]@{
                fqdn = $unicodeDomain
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $expectedUri = Get-DnsPersistAccountUri -Domain 'xn--bcher-kva.de' -AccountHashPrefix $prefix
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ($output -replace '\s+', '') | Should -Match ([regex]::Escape("_validation-persist.xn--bcher-kva.de->`"authority.example;accounturi=$expectedUri`""))
    }

    It "Normalizes each Unicode domain supplied through the pipeline" {
        $otherDomain = [string]::Concat('m', [char]0x00FC, 'nchen.de.')
        $output = $unicodeDomain, $otherDomain | Publish-DnsPersistChallenge `
            -HashedAccountUri 'https://ca.example/account-hash/sha-256/external' `
            -IssuerDomainName 'authority.example' -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        $output | Should -Match '_validation-persist\.xn--bcher-kva\.de ->'
        $output | Should -Match '_validation-persist\.xn--mnchen-3ya\.de ->'
    }

    It "Skips wildcard order auths with NoAutoWildcard while publishing other auths" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            @('*.example.com','www.example.com') | ForEach-Object {
                [pscustomobject]@{
                    fqdn = $_
                    challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
                }
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs -NoAutoWildcard 3>&1 6>&1 | Out-String

        $output | Should -Match 'Skipping \*\.example\.com'
        $output | Should -Match '_validation-persist\.www\.example\.com ->'
        $output | Should -Not -Match '_validation-persist\.example\.com ->'
    }

    It "Automatically adds wildcard policy for wildcard order auths" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            [pscustomobject]@{
                fqdn = '*.example.com'
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ($output -replace '\s+', '') | Should -Match '_validation-persist\.example\.com->"authority\.example;accounturi=[^";]+;policy=wildcard"'
    }

    It "Publishes a wildcard order auth when AllowWildcard overrides NoAutoWildcard" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            [pscustomobject]@{
                fqdn = '*.example.com'
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs -NoAutoWildcard -AllowWildcard 6>&1 | Out-String

        $output | Should -Match '_validation-persist\.example\.com ->'
        $output | Should -Match 'policy=wildcard'
    }

    It "Keeps only the wildcard record at the same owner and removes exact duplicates" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            @('example.com','*.example.com','example.com') | ForEach-Object {
                [pscustomobject]@{
                    fqdn = $_
                    challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
                }
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ([regex]::Matches($output, '_validation-persist\.example\.com ->')).Count | Should -Be 1
        ([regex]::Matches($output, 'policy=wildcard')).Count | Should -Be 1
    }

    It "Keeps separate records for different issuers at the same owner" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            @('authority.example','other.example') | ForEach-Object {
                [pscustomobject]@{
                    fqdn = 'example.com'
                    challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @($_) })
                }
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ([regex]::Matches($output, '_validation-persist\.example\.com ->')).Count | Should -Be 2
        $output | Should -Match 'authority\.example; accounturi='
        $output | Should -Match 'other\.example; accounturi='
    }

    It "Keeps the wildcard record when it precedes the base authorization" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            @('*.example.com','example.com','*.example.com') | ForEach-Object {
                [pscustomobject]@{
                    fqdn = $_
                    challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
                }
            }
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ([regex]::Matches($output, '_validation-persist\.example\.com ->')).Count | Should -Be 1
        ([regex]::Matches($output, 'policy=wildcard')).Count | Should -Be 1
    }

    It "Uses directory metadata for pre-provisioning defaults" {
        Mock -ModuleName Posh-ACME Get-PAServer {
            [pscustomobject]@{ meta = [pscustomobject]@{
                issuerDomainNames = @('z.example','a.example')
                accountHashPrefix = 'https://ca.example/account-hash/'
            } }
        }
        $output = Publish-DnsPersistChallenge -Domain 'example.com' -AccountUri 'https://ca.example/acct/123' `
            -KeyThumbprint 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs' `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        ($output -replace '\s+', '') | Should -Match '_validation-persist\.example\.com->"a\.example;accounturi=https://ca\.example/account-hash/sha-256/'
    }

    It "Rejects missing directory metadata before publishing" {
        Mock -ModuleName Posh-ACME Get-PAServer { [pscustomobject]@{ meta = [pscustomobject]@{} } }
        $details = @{
            Domain = 'example.com'
            AccountUri = 'https://ca.example/acct/123'
            KeyThumbprint = 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs'
            Plugin = 'Manual'
            PluginArgs = $pluginArgs
        }

        { Publish-DnsPersistChallenge @details } | Should -Throw '*IssuerDomainName*'
        $details.IssuerDomainName = 'authority.example'
        { Publish-DnsPersistChallenge @details } | Should -Throw '*AccountHashPrefix*'
    }

    It "Skips order auths with missing challenges or issuer names" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            @(
                [pscustomobject]@{ fqdn = 'missing.example.com'; challenges = @() }
                [pscustomobject]@{ fqdn = 'bad.example.com'; challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @() }) }
            )
        }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs 3>&1 6>&1 | Out-String

        $output | Should -Match 'contains no dns-persist-01 challenge'
        $output | Should -Match 'Unable to determine issuer domain name'
        $output | Should -Not -Match '_validation-persist\.'
    }

    It "Queues exact TXT values for one plugin save with a shared expiration" {
        $hashedUri = 'https://ca.example/account-hash/sha-256/external'
        $expiration = [DateTimeOffset]::Parse('2027-04-01T00:00:00Z')
        $output = Publish-DnsPersistChallenge -Domain 'example.com','www.example.com' `
            -HashedAccountUri $hashedUri -IssuerDomainName 'authority.example' `
            -Plugin Manual -PluginArgs $pluginArgs -AllowWildcard -PersistUntil $expiration 6>&1 | Out-String

        $records = $output -replace '\s+', ''
        $records | Should -Match ([regex]::Escape("_validation-persist.example.com->`"authority.example;accounturi=$hashedUri;policy=wildcard;persistUntil=1806537600`""))
        $records | Should -Match ([regex]::Escape("_validation-persist.www.example.com->`"authority.example;accounturi=$hashedUri;policy=wildcard;persistUntil=1806537600`""))
        ([regex]::Matches($output, 'Please create the following TXT records:')).Count | Should -Be 1
    }

    It "Uses the domain-correlation opt-out when pre-provisioning from an account" {
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { 'https://ca.example/hash/shared' }
        $output = Publish-DnsPersistChallenge -Domain 'example.com' -Account $account `
            -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -NoDomainCorrelationMitigation -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq '*' }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Uses the domain-correlation opt-out with explicit account details" {
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { 'https://ca.example/hash/shared' }
        $output = Publish-DnsPersistChallenge -Domain 'www.example.com' `
            -AccountUri 'https://ca.example/acct/123' -KeyThumbprint 'thumbprint' `
            -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -NoDomainCorrelationMitigation -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq '*' }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.www\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Uses the domain-correlation opt-out for order challenges" {
        Mock -ModuleName Posh-ACME Get-PAAuthorization {
            [pscustomobject]@{
                fqdn = 'order.example.com'
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; issuerDomainNames = @('authority.example') })
            }
        }
        Mock -ModuleName Posh-ACME Get-DnsPersistAccountUri { 'https://ca.example/hash/shared' }
        $order = [pscustomobject]@{ PSTypeName = 'PoshACME.PAOrder'; Plugin = @('Manual'); authorizations = @('https://ca.example/authz/1') }
        $output = Publish-DnsPersistChallenge -Order $order -AccountHashPrefix $prefix `
            -Plugin Manual -PluginArgs $pluginArgs -NoDomainCorrelationMitigation 6>&1 | Out-String

        Should -Invoke Get-DnsPersistAccountUri -Exactly 1 -ModuleName Posh-ACME -ParameterFilter { $Domain -eq '*' }
        ($output -replace '\s+', '') | Should -Match '_validation-persist\.order\.example\.com->"authority\.example;accounturi=https://ca\.example/hash/shared"'
    }

    It "Rejects the domain-correlation switch with a caller-supplied hashed URI" {
        {
            Publish-DnsPersistChallenge -Domain 'example.com' -HashedAccountUri 'https://ca.example/hash/external' `
                -IssuerDomainName 'authority.example' -NoDomainCorrelationMitigation -Plugin Manual
        } | Should -Throw
    }

    It "Serializes published challenges and appends them to the cache" {
        $cachePath = 'TestDrive:\PersistedChallenges.json'
        $existing = [pscustomobject]@{
            fqdn = 'keep.example.com'
            issuer = 'other-authority.example'
            hashAcctUri = 'https://ca.example/hash/existing'
            addWildcard = $false
            persistUntil = $null
            fromAcctUri = ''
            fromAcctThumb = ''
        }
        ConvertTo-Json -InputObject @($existing) -Depth 5 | Set-Content $cachePath

        $accountUri = 'https://ca.example/acct/persist'
        $thumbprint = 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs'
        $expiration = [DateTimeOffset]::Parse('2027-04-01T00:00:00Z')
        $expectedUri = Get-DnsPersistAccountUri -Domain 'persist.example.com' -AccountUri $accountUri `
            -KeyThumbprint $thumbprint -AccountHashPrefix $prefix

        Publish-DnsPersistChallenge -Domain '*.persist.example.com' -AccountUri $accountUri `
            -KeyThumbprint $thumbprint -AccountHashPrefix $prefix -IssuerDomainName 'authority.example' `
            -Plugin Manual -PluginArgs $pluginArgs -AllowWildcard -PersistUntil $expiration 6>&1 | Out-Null

        $records = Get-Content $cachePath -Raw | ConvertFrom-Json
        $records = @($records)
        $records | Should -HaveCount 2
        ($records | Where-Object fqdn -eq 'keep.example.com').issuer | Should -Be 'other-authority.example'

        $record = $records | Where-Object fqdn -eq 'persist.example.com'
        $record | Should -Not -BeNullOrEmpty
        $record.issuer | Should -Be 'authority.example'
        $record.hashAcctUri | Should -Be $expectedUri
        $record.addWildcard | Should -BeTrue
        $record.persistUntil | Should -Be '1806537600'
        $record.fromAcctUri | Should -Be $accountUri
        $record.fromAcctThumb | Should -Be $thumbprint
    }

    It "Does not append an already cached challenge" {
        $cachePath = 'TestDrive:\PersistedChallenges.json'
        $record = [pscustomobject]@{
            fqdn = 'persist.example.com'
            issuer = 'authority.example'
            hashAcctUri = 'https://ca.example/hash/existing'
            addWildcard = $false
            persistUntil = $null
            fromAcctUri = ''
            fromAcctThumb = ''
        }
        ConvertTo-Json -InputObject @($record) -Depth 5 | Set-Content $cachePath

        Publish-DnsPersistChallenge -Domain 'persist.example.com' `
            -HashedAccountUri 'https://ca.example/hash/existing' -IssuerDomainName 'authority.example' `
            -Plugin Manual -PluginArgs $pluginArgs 6>&1 | Out-Null

        $records = Get-Content $cachePath -Raw | ConvertFrom-Json
        $records = @($records)
        $records | Should -HaveCount 1
        $records[0].fqdn | Should -Be 'persist.example.com'
        $records[0].hashAcctUri | Should -Be 'https://ca.example/hash/existing'
    }
}
