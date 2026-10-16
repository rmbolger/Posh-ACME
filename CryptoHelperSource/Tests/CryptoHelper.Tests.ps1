Describe 'CryptoHelper' {

    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
        if ($IsCoreCLR) {
            $existingPath = Join-Path $PSScriptRoot '../../Posh-ACME/lib/BC.Crypto.1.8.8.2-netstandard2.0.dll'
            Add-Type -LiteralPath $existingPath
        }
        Import-Module $modulePath -Force -ErrorAction Stop

        $chainPath = Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot/srvr1/acct1/example.com/chain0.cer'
        $certificates = [regex]::Matches((Get-Content $chainPath -Raw),
            '-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----',
            [Text.RegularExpressions.RegexOptions]::Singleline)
    }

    It 'Hashes UTF-8 input with SHA3-256' {
        'abc' | Get-BCSha3Hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
    }

    It 'Returns issuer CNs from the chain certificates' {
        $certificates.Count | Should -Be 2
        $certificates[0].Value | Get-BCCertificateIssuer | Should -BeExactly '(STAGING) Pretend Pear X1'
        $certificates[1].Value | Get-BCCertificateIssuer | Should -BeExactly '(STAGING) Doctored Durian Root CA X3'
    }

    It 'Exports both cmdlets after force re-import' {
        Import-Module $modulePath -Force -ErrorAction Stop
        (Get-Module CryptoHelper).ExportedCmdlets.Keys | Should -Contain 'Get-BCSha3Hash'
        (Get-Module CryptoHelper).ExportedCmdlets.Keys | Should -Contain 'Get-BCCertificateIssuer'
        'abc' | Get-BCSha3Hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
    }

    It 'Loads the packaged BouncyCastle dependency in the expected context' {
        $assemblies = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -in 'BouncyCastle.Cryptography', 'BouncyCastle.Crypto', 'BC.Crypto'
        })
        if ($IsCoreCLR) {
            $isolated = @($assemblies | Where-Object {
                [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_).Name -eq 'CryptoHelper'
            })
            $default = @($assemblies | Where-Object {
                [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_) -eq [Runtime.Loader.AssemblyLoadContext]::Default
            })
            $isolated | Should -HaveCount 1
            $default | Should -HaveCount 1
        } else {
            @($assemblies | Where-Object { $_.GetName().Name -eq 'BouncyCastle.Cryptography' }) | Should -HaveCount 1
        }
    }

    It 'Uses the embedded issuer parser from Posh-ACME' {
        $previousHome = $env:POSHACME_HOME
        try {
            Get-ChildItem (Join-Path $PSScriptRoot '../../Tests/TestFiles/ConfigRoot') |
                Copy-Item -Destination 'TestDrive:\' -Recurse
            $env:POSHACME_HOME = 'TestDrive:\'
            Import-Module (Join-Path $PSScriptRoot '../../Posh-ACME/Posh-ACME.psd1') -Force
            Mock -ModuleName Posh-ACME Import-Pem { throw 'Legacy PEM parser was called.' }

            $issuers = InModuleScope Posh-ACME {
                Get-ChainIssuers -OrderFolder 'TestDrive:\srvr1\acct1\example.com'
            }
            $issuers | Should -HaveCount 3
            $issuers[0].issuer | Should -Be '(STAGING) Pretend Pear X1'
            $issuers[1].issuer | Should -Be '(STAGING) Doctored Durian Root CA X3'
        }
        finally {
            Remove-Module Posh-ACME -ErrorAction Ignore
            $env:POSHACME_HOME = $previousHome
        }
    }

    It 'Uses CryptoHelper for the SOLIDServer SHA3 fallback' {
        Import-Module (Join-Path $PSScriptRoot '../../Posh-ACME/Posh-ACME.psd1') -Force
        $pluginPath = Join-Path $PSScriptRoot '../../Posh-ACME/Plugins/SOLIDServer.ps1'
        try {
            $hash = InModuleScope Posh-ACME -Parameters @{ PluginPath = $pluginPath } {
                . $PluginPath
                Get-SHA3_256 'abc'
            }
            $hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
        }
        finally {
            Remove-Module Posh-ACME -ErrorAction Ignore
        }
    }
}
