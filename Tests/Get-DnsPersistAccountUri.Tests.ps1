Describe "Get-DnsPersistAccountUri" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force

        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        InModuleScope Posh-ACME { Import-PAConfig }
        $account = Get-PAAccount -ID acct1
    }

    It "Converts IDN input to its A-label form" {
        # Powershell 5.1 doesn't seem to like Unicode domain literals directly, so we construct it using [char] codes
        $unicodeDomain = [string]::Concat('b', [char]0x00FC, 'cher.de.')
        $unicodeUri = Get-DnsPersistAccountUri -Domain $unicodeDomain -Account $account -AccountHashPrefix 'https://ca.example/account-hash/'
        $asciiUri = Get-DnsPersistAccountUri -Domain 'xn--bcher-kva.de' -Account $account -AccountHashPrefix 'https://ca.example/account-hash/'

        $unicodeUri | Should -Be $asciiUri
    }

    It "Strips wildcard prefixes" {
        $plainUri = Get-DnsPersistAccountUri -Domain 'example.com' -Account $account -AccountHashPrefix 'https://ca.example/account-hash/'
        $prefixedUri = Get-DnsPersistAccountUri -Domain '*.Example.com.' -Account $account -AccountHashPrefix 'https://ca.example/account-hash/'

        $prefixedUri | Should -Be $plainUri
    }

    It "Hashes the domain length as a single octet" {
        $accountKeyAuthorization = Get-KeyAuthorization -Token 'test' -Account $account
        $thumbprint = $accountKeyAuthorization.Split('.')[1]
        $hashInput = [Collections.Generic.List[byte]]::new()
        $hashInput.Add([byte]11)
        $hashInput.AddRange([Text.Encoding]::ASCII.GetBytes('example.com'))
        $hashInput.AddRange([Text.Encoding]::ASCII.GetBytes($thumbprint))
        $hashInput.AddRange([Text.Encoding]::ASCII.GetBytes($account.location))
        $sha256 = [Security.Cryptography.SHA256]::Create()
        $expectedHash = [Convert]::ToBase64String($sha256.ComputeHash($hashInput.ToArray())).TrimEnd('=').Replace('+','-').Replace('/','_')
        $expectedUri = "https://ca.example/account-hash/sha-256/$expectedHash"

        $actualUri = Get-DnsPersistAccountUri -Domain 'example.com' -Account $account -AccountHashPrefix 'https://ca.example/account-hash/'
        $actualUri | Should -Be $expectedUri
    }

    It "Matches the draft 02 section 10.2 hashed URI example" {
        $actualUri = Get-DnsPersistAccountUri `
            -Domain 'example.com' `
            -AccountUri 'https://ca.example/acct/123' `
            -KeyThumbprint 'NzbLsXh8uDCcd-6MNwXF4W_7noWXFZAfHkxZsRGC9Xs' `
            -AccountHashPrefix 'https://ca.example/account-hash/'

        $actualUri | Should -Be 'https://ca.example/account-hash/sha-256/5SQm7n6tPh2-PlLbCKGnViTXX5z19SCN4cPGQHSk-kw'
    }

    It "Rejects invalid normalized domains" -TestCases @(
        @{ Domain = '   '; Reason = 'empty domain' }
        @{ Domain = '.'; Reason = 'no labels' }
        @{ Domain = 'example..com'; Reason = 'empty label' }
        @{ Domain = '-example.com'; Reason = 'label starts with hyphen' }
        @{ Domain = 'example-.com'; Reason = 'label ends with hyphen' }
        @{ Domain = ('a' * 64) + '.com'; Reason = 'label longer than 63 octets' }
        @{ Domain = (('a' * 63) + '.' * 1) * 4; Reason = 'domain longer than 253 octets' }
    ) {
        { Get-DnsPersistAccountUri -Domain $Domain -Account $account -AccountHashPrefix 'https://ca.example/account-hash/' } | Should -Throw
    }

}
