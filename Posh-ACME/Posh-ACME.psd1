@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.35.0'
GUID = 'f14adab4-278e-4dcb-b843-421fa5a5e688'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = @'
ACME protocol client for obtaining certificates using Let''s Encrypt (or other ACME compliant CA)
This is a custom build intended allow compatibility with .NET 4.6.1. It should not be used with PowerShell Core and you should only attempt to use RSA based key options.
'@
CompatiblePSEditions = @('Desktop','Core')
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.6.1'

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @(
    'lib\BC.Crypto.1.8.8.dll'
    'System.Net.Http'
)

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Posh-ACME.Format.ps1xml'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Complete-PAOrder'
    'Export-PAAccountKey'
    'Get-DnsPersistAccountUri'
    'Get-DnsAcctLabel'
    'Get-KeyAuthorization'
    'Get-PAAccount'
    'Get-PAAuthorization'
    'Get-PACertificate'
    'Get-PAOrder'
    'Get-PAPlugin'
    'Get-PAPluginArgs'
    'Get-PAProfile'
    'Get-PAServer'
    'Get-PublishedPersistChallenge'
    'Install-PACertificate'
    'Invoke-HttpChallengeListener'
    'New-PAAccount'
    'New-PACertificate'
    'New-PAOrder'
    'New-PAAuthorization'
    'Publish-Challenge'
    'Publish-DnsPersistChallenge'
    'Remove-PAAccount'
    'Remove-PAOrder'
    'Remove-PAServer'
    'Revoke-PAAuthorization'
    'Revoke-PACertificate'
    'Save-Challenge'
    'Send-ChallengeAck'
    'Set-PAAccount'
    'Set-PAOrder'
    'Set-PAServer'
    'Submit-ChallengeValidation'
    'Submit-OrderFinalize'
    'Submit-Renewal'
    'Unpublish-Challenge'
    'Unpublish-DnsPersistChallenge'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(
    'Get-PAAuthorizations'
)

PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'LetsEncrypt','ssl','tls','certificates','acme'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-ACME/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-ACME'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
## 4.35.0 (2026-10-11)

* Posh-ACME now fully supports the new `dns-persist-01` challenge type based on [draft-ietf-acme-dns-persist-02](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-persist/). The module still works with draft 01 based ACME servers, but the `_validation-persist` records must already exist or you must use the Advanced parameter set from `Publish-DnsPersistChallenge` to publish draft 01 compatible records. There are no available draft 02 ACME CAs to test against yet, so testing has been largely theoretical and bugs may surface once there is something real to test against.
  * *Breaking Change:* `-UseAllDomains` has been removed from (Un)Publish-DnsPersistChallenge and they no longer attempt to skip records that would be covered by another wildcard record.
  * *Breaking Change:* The FromOrder parameter set on (Un)Publish-DnsPersistChallenge should still work the same way, but it will now only work against draft 02+ compatible ACME servers.
  * *Breaking Change:* Wildcard FQDNs passed to (Un)Publish-DnsPersistChallenge will now automatically have `policy=wildcard` added to that specific record without needing to pass the `-AllowWildcard` switch. Using the switch still adds it to all records being processed.
  * *Breaking Change:* The Standalone parameter set on (Un)Publish-DnsPersistChallenge has been replaced by 3 new parameter sets. See the function docs and persist guide for details.
* 3 new parameter sets for (Un)Publish-DnsPersistChallenge that allow for more pre-provisioning use cases, some of which don't require publishing from the same system you request the certs from. See the function docs and persist guide for details.
* New `Get-DnsPersistAccountUri` function which calculates the hashed accountUri field required in draft 02 compatible persistent records.
* New `Get-PublishedPersistChallenge` function which returns the details of persistent records published from the current Posh-ACME config. The objects returned by this function can be piped to (Un)Publish-DnsPersistChallenge.
* `Get-PAAccount` now returns two additional fields
  * `pubkey` which is a public-only version of the existing ACME account `key` value
  * `thumbprint` which is the JWK thumbprint value of the ACME account key
  * The default display output for a PAAccount object now includes the thumbprint by default
* `dns-persist-01` has been added to the allowed values for `-DnsVariant` on New-PACertificate, New-PAOrder, and Set-PAOrder.
* The `-DnsVariant` parameter on the older (Un)Publish-Challenge functions only allows `dns-01` and `dns-account-01`.
* No user-facing changes to `Submit-ChallengeValidation`, but lots of refactoring internally to support the various dns-persist-01 workflows.
* New "shared" PluginArgs parameter, `PublishPersist`, which must be `$true` if you want a dns-persist-01 enabled order to automatically attempt to re-publish the necessary persistent records on each renewal. This shouldn't be necessary when using pre-provisioning.
* Added "DNS Challenge Variants" guide
* Added "Using Persistent DNS Challenges" guide
* New [DNSMint](https://dnsmint.com/) plugin (#690) (Thanks @kxbnb)
* Fixed orders using `-CSRPath` throwing an error with CSRs that have the SAN field marked as critical. (#692) (Thanks @nimbice)
* Fixed parsing of RSA private keys that contained leading zeroes in some fields. (#694) (Thanks @nimbice)
* Fixed an internal typo related to HurricaneElectricDyn plugin name affecting output of `Get-PAPlugin` and some verbose logging (#695) (Thanks @nimbice)
* Fixed some dead or redirecting links in the readme (#696) (Thanks @mikeweinberg)
* Fixed `-CSRPath` workflows ignoring IP SAN fields in the parsed CSR. (#699)
* Fixed `Set-PAOrder` skipping the cert re-export when `-Profile` is also changed (#698) (Thanks @nimbice)
* Fixed ARI check using previous order's window when a request fails (#697) (Thanks @nimbice)
* Fixed `Complete-PAOrder` using the current order instead of a specified order for cert detail output and installation. (#700) (Thanks @nimbice)
* Fixed orders using `-OCSPMustStaple` failing to generate a CSR. (#701) (Thanks @nimbice)
* Fixed `Get-PAAccount` and `Test-ValidPlugin` edge case bugs. (#702) (Thanks @nimbice)
* Fixed a bug when using `Set-PAAccount` with both `-NewName` and `-NoSwitch`. (#703) (Thanks @nimbice)
'@

    }

}

}
