@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.9.0'
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
## 4.9.0 (2021-09-21)

* Added new DNS plugin [ISPConfig](https://www.ispconfig.org/)
* Fixed the DOCean plugin when used with accounts that have more than 20 zones. (#384) (Thanks @Xpyder)
* Fixed a bug in the DOCean plugin that prevented publishing records against the zone apex.
* Fixed a bug using `Set-PAOrder -PreferredChain` on an existing but expired order that was recently upgraded from Posh-ACME 3.x.
* Fixed renewal window calculation for certs that have lifetimes shorter or longer than 90 days. (#382) (Thanks @lookcloser)
  * Due to the bug, certs with lifetimes longer than 90 days would renew early and certs with lifetimes shorter than 90 days would renew late or potentially not at all. Because the renewal window is calculated and saved at finalization time, the new module version won't fix the value on existing orders. It will only fix future orders/renewals.
  * If you want to scan for and fix any orders that might have been affected by this bug, you can use the script posted here: https://github.com/rmbolger/Posh-ACME/issues/382#issuecomment-922128237
* Fixed a benign bug with object serialization in PS 5.1 that was saving the dynamic attributes on server/account/order objects.
'@

    }

}

}
