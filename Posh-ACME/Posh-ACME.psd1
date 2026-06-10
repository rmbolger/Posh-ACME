@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.33.0'
GUID = '5f52d490-68dd-411c-8252-828c199a4e63'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'ACME protocol client for obtaining certificates using Let''s Encrypt (or other ACME compliant CA)'
CompatiblePSEditions = @('Desktop','Core')
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.1'

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @(
    'lib\BC.Crypto.1.8.8.2-netstandard2.0.dll'
    'System.Net.Http'
)

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Posh-ACME.Format.ps1xml'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Complete-PAOrder'
    'Export-PAAccountKey'
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
        Tags = 'LetsEncrypt','ssl','tls','certificates','acme','Linux','Mac'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-ACME/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-ACME'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
## 4.33.0 (2026-06-09)

* Added preliminary support for `dns-account-01` challenge type based on [draft-ietf-acme-dns-account-label-03](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-account-label/03/).
  * New `-DnsVariant` parameter in various Order and Challenge related functions.
  * New `Get-DnsAcctLabel` utility function
* New `-UsePfxDerEncoding` to `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder` which changes the encoding within generated PFX files from BER to DER. This may be necessary for compatibility with some applications, libraries, or services that have deprecated BER support. (#674)
* New [HostUp](https://cloud.hostup.se/) plugin (#663) (Thanks @itssimple)
* Cloudflare: Fixed a bug with TXT records containing quotes and did some light refactoring
* GoDaddy: Added support for corporate (Brandsight) API access which requires a Customer ID value. (#660) (Thanks @vertras)
* GoDaddy: Fixed support for TXT records containing quotes
* Namecheap: Reduced required API permissions for delegated corporate accounts to just `domains.dns.*` (#672)
* Namecheap: Added Sandbox support and better debug logging
* Namecheap: Fixed TXT records containing quotes and apex record support
* AutoDNS: Fixed string formatting error when using a password containing curly braces (#671)
* Fixed a PowerShell 5.1 specific bug in `Publish-DnsPersistChallenge` and `Unpublish-DnsPersistChallenge`
* Disabled PowerShell native debug logging on low level ACME calls which is now way more verbose in 7.6 and was duplicating the module specific logging.
'@

    }

}

}
