Describe "PersistAncestor helpers" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    Context "ConvertTo-PersistAncestor" {

        It "Normalizes case and trailing dot" {
            InModuleScope Posh-ACME {
                ConvertTo-PersistAncestor 'Example.COM.' | Should -Be 'example.com'
            }
        }

        It "Rejects <Value>" -ForEach @(
            @{ Value = '*.example.com' }
            @{ Value = '192.0.2.1' }
            @{ Value = '2001:db8::1' }
            @{ Value = 'localhost' }
            @{ Value = 'bad_label.example.com' }
        ) {
            InModuleScope Posh-ACME -Parameters @{ Value = $Value } {
                { ConvertTo-PersistAncestor $Value } | Should -Throw
            }
        }

        It "Rejects names whose _validation-persist form exceeds 253 characters" {
            InModuleScope Posh-ACME {
                $label = 'a' * 60
                $name = (@($label, $label, $label, $label) -join '.')
                { ConvertTo-PersistAncestor $name } | Should -Throw
            }
        }
    }

    Context "Get-PersistAncestor" {

        It "Returns the longest proper ancestor" {
            InModuleScope Posh-ACME {
                Get-PersistAncestor 'a.b.example.com' @('example.com','b.example.com') | Should -Be 'b.example.com'
            }
        }

        It "Does not match the identifier itself" {
            InModuleScope Posh-ACME {
                Get-PersistAncestor 'example.com' @('example.com') | Should -BeNullOrEmpty
            }
        }

        It "Requires a whole-label match" {
            InModuleScope Posh-ACME {
                Get-PersistAncestor 'notexample.com' @('example.com') | Should -BeNullOrEmpty
            }
        }

        It "Returns nothing when no ancestor applies" {
            InModuleScope Posh-ACME {
                Get-PersistAncestor 'sub.example.com' @('other.org') | Should -BeNullOrEmpty
            }
        }
    }
}

Describe "Submit-ChallengeValidation PersistAncestor" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force

        function New-TestOrder([string]$DnsVariant='dns-persist-01', [bool]$Serial=$false) {
            $o = [pscustomobject]@{
                Name = 'order1'; status = 'pending'; DnsVariant = $DnsVariant; Plugin = @('Manual','Manual','Manual'); DnsAlias = @('')
                UseSerialValidation = $Serial; DnsSleep = 0; ValidationTimeout = 60
            }
            $o.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
            $o
        }

        function New-TestAuth([string]$Value, [string]$Type, [int]$Index) {
            [pscustomobject]@{
                identifier = [pscustomobject]@{ type = $Type; value = $Value }
                DNSId      = $Value
                fqdn       = $Value
                wildcard   = $false
                status     = 'pending'
                location   = "https://ca.example/authz/$Index"
                challenges = @([pscustomobject]@{ type = 'dns-persist-01'; token = 'tok'; url = "https://ca.example/chal/$Index" })
            }
        }
    }

    BeforeEach {
        # mocks read the authorizations from a global since Pester mocks can't see test-scope variables
        $global:TestAuths = @()
        Mock Get-PAAccount -ModuleName Posh-ACME {
            $a = [pscustomobject]@{ status = 'valid' }
            $a.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
            $a
        }
        Mock Get-PAOrder -ModuleName Posh-ACME { [pscustomobject]@{ Name = 'order1' } }
        Mock Get-PAAuthorization -ModuleName Posh-ACME { $global:TestAuths }
        Mock Get-PAPluginArgs -ModuleName Posh-ACME {
            [pscustomobject]@{ PersistAncestor = @('example.com','b.example.com'); PublishPersist = $false }
        }
        Mock Get-IssuerFromChallenge -ModuleName Posh-ACME { 'authority.example' }
        Mock Test-PersistUntilExpiry -ModuleName Posh-ACME {}
        Mock Publish-Challenge -ModuleName Posh-ACME {}
        Mock Unpublish-Challenge -ModuleName Posh-ACME {}
        Mock Save-Challenge -ModuleName Posh-ACME {}
        Mock Send-ChallengeAck -ModuleName Posh-ACME {}
        Mock Wait-AuthValidation -ModuleName Posh-ACME {}
    }

    AfterAll {
        Remove-Variable -Name TestAuths -Scope Global -ErrorAction SilentlyContinue
    }

    It "Sends each DNS identifier's nearest ancestor in batch mode and none for IP identifiers" {
        $global:TestAuths = @(
            New-TestAuth 'a.b.example.com' 'dns' 1
            New-TestAuth 'other.example.com' 'dns' 2
            New-TestAuth '192.0.2.1' 'ip' 3
        )
        New-TestOrder | Submit-ChallengeValidation

        Should -Invoke Send-ChallengeAck -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { $AncestorDomain -eq 'b.example.com' }
        Should -Invoke Send-ChallengeAck -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { $AncestorDomain -eq 'example.com' }
        Should -Invoke Send-ChallengeAck -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { -not $AncestorDomain }
    }

    It "Checks expiry against the ancestor record when one applies" {
        $global:TestAuths = @(New-TestAuth 'a.b.example.com' 'dns' 1)
        New-TestOrder | Submit-ChallengeValidation

        Should -Invoke Test-PersistUntilExpiry -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { $Identifier -eq 'b.example.com' }
    }

    It "Sends the ancestor with the serial validation ack" {
        $global:TestAuths = @(New-TestAuth 'a.b.example.com' 'dns' 1)
        New-TestOrder -Serial $true | Submit-ChallengeValidation

        Should -Invoke Send-ChallengeAck -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { $AncestorDomain -eq 'b.example.com' }
    }

    It "Warns and sends no ancestor when no PersistAncestor value matches" {
        Mock Write-Warning -ModuleName Posh-ACME {}
        $global:TestAuths = @(New-TestAuth 'a.unrelated.net' 'dns' 1)
        New-TestOrder | Submit-ChallengeValidation

        Should -Invoke Write-Warning -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { $Message -like "*a.unrelated.net*" }
        Should -Invoke Send-ChallengeAck -ModuleName Posh-ACME -Times 1 -Exactly -ParameterFilter { -not $AncestorDomain }
    }

    It "Throws when PersistAncestor is used without dns-persist-01" {
        $global:TestAuths = @(New-TestAuth 'a.b.example.com' 'dns' 1)
        { New-TestOrder -DnsVariant 'dns-01' | Submit-ChallengeValidation } | Should -Throw "*requires the order DnsVariant*"
        Should -Invoke Publish-Challenge -ModuleName Posh-ACME -Times 0 -Exactly
    }

    It "Throws when PersistAncestor is combined with PublishPersist" {
        Mock Get-PAPluginArgs -ModuleName Posh-ACME {
            [pscustomobject]@{ PersistAncestor = @('example.com'); PublishPersist = $true }
        }
        $global:TestAuths = @(New-TestAuth 'a.b.example.com' 'dns' 1)
        { New-TestOrder | Submit-ChallengeValidation } | Should -Throw "*cannot be combined with PublishPersist*"
        Should -Invoke Send-ChallengeAck -ModuleName Posh-ACME -Times 0 -Exactly
    }
}
