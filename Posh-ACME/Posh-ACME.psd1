@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.14.0'
GUID = '5f52d490-68dd-411c-8252-828c199a4e63'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'ACME protocol client for obtaining certificates using Let''s Encrypt (or other ACME compliant CA)'
CompatiblePSEditions = @('Desktop','Core')
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.1'

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @(
    'lib\BC.Crypto.1.9.0-netstandard2.0.dll'
    'System.Net.Http'
)

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Posh-ACME.Format.ps1xml'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Complete-PAOrder'
    'Export-PAAccountKey'
    'Get-KeyAuthorization'
    'Get-PAAccount'
    'Get-PAAuthorization'
    'Get-PACertificate'
    'Get-PAOrder'
    'Get-PAPlugin'
    'Get-PAPluginArgs'
    'Get-PAServer'
    'Install-PACertificate'
    'Invoke-HttpChallengeListener'
    'New-PAAccount'
    'New-PACertificate'
    'New-PAOrder'
    'New-PAAuthorization'
    'Publish-Challenge'
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
## 4.14.0 (2022-04-12)

* Added new DNS plugin [Porkbun](https://porkbun.com/) (Thanks @CaiB)
* Added server shortcuts for Google's new ACME CA, GOOGLE_PROD and GOOGLE_STAGE.
* Added server shortcuts for SSL.com, SSLCOM_RSA and SSLCOM_ECC.
* Added `UseAltAccountRefresh` switch to `Set-PAServer` to workaround CAs that don't yet support direct account refreshes such as Google, SSL.com, and DigiCert. (#372) (#394)
  * New configs should have this set by default for CAs known to need it. But you will need to explicitly set it on any existing configs for these CAs.
* Added `LifetimeDays` param on `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder` to enable user requested cert lifetimes for ACME CAs that support the feature.
  * Google's CA is the only free ACME CA known to currently support this and the order lifetime cannot be changed once it is created. Setting a new value on an existing order will only change the lifetime on subsequent renewals.
* Updated Azure plugin to use the latest stable API version.
* Updated Azure guide to account for breaking changes in the Az module.
* Fixed GoDaddy plugin when using it with delegated sub-zones. (#430)
* Fixed `New-PAAccount` when importing an existing key on CAs that require external account binding.
* Reduced the number of account refreshes that happen as part of normal operations.

'@

    }

}

}
