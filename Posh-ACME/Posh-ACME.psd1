@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.32.0'
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
## 4.32.0 (2026-03-29)

* New [DNSExit](https://dnsexit.com/) plugin (#668) (Thanks @joxdev13)
* Preliminary support for [dns-persist-01](https://datatracker.ietf.org/doc/draft-ietf-acme-dns-persist/)
  * Adds functions `Publish-DnsPersistChallenge` and `Unpublish-DnsPersistChallenge`. These are subject to change while the spec is still in a draft state.
  * I wanted to get these released early so folks can start testing the DNS plugins with them. No other core module changes have been added to support the cert workflow for this challenge type yet.
  * It is **highly** recommended to test these functions using your preferred DNS plugin. I suspect there are some bugs in some of the plugins that might surface because they have only been tested creating ACME challenge TXT records until now. Please submit issues for plugins that have problems.
* Fixed bug in Infoblox plugin that caused errors when TxtValue required URL escaping
* Added better error handling in `Get-PAPluginArgs` when decrypting encrypted args fails (#654)

### Potentially Breaking Change

* Generated CSRs no longer include the Enhanced Key Usage (EKU) extension.
  * This is a fix for CAs that have started rejecting CSRs containing the Client Authentication EKU such as [Google](https://pki.goog/updates/may2025-clientauth.html) due to its deprecation across all public CAs.
  * This change has been tested successfully against all known free public ACME CAs. The resulting certs still contain the EKU extension, but which EKUs get added is dependent on the CA as it has always been.
  * However, there are many commercial and private CAs I was unable to test against which is why this *might* be a breaking change for them. PLEASE test if you're not using one of the free public ACME CAs.
  * If for some reason your preferred CA rejects the new CSRs, you may always fall back to supplying your own CSR using the `-CSRPath` param in many of the functions.
'@

    }

}

}
