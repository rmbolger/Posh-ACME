@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.29.0'
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
    'Get-PAProfile'
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
## 4.29.0 (2025-06-25)

* New DNS Plugins
  * [Netcup](https://www.netcup.com) (#602)
  * [TransIP](https://www.transip.nl) (#622) (Thanks @Tim81)
* Added `-IgnoreContact` switch to `Set-PAServer` (#619)
  * ALL USERS of LET'S ENCRYPT, this switch works around a bug that causes a new account to be created for every renewal after LE shut down their automated email warning service.
  * This option causes the module to ignore any `-Contact` parameters in functions that support it when using the associated server.
  * It will be enabled by default on new installs that use Let's Encrypt. But existing users will need to manually enable it *OR* simply stop using the `-Contact` parameter in your scripts when using Let's Encrypt ACME endpoints.
* Added AZAccessTokenSecure param for Azure plugin (#618)
* Added WinSkipCACheck switch to Windows plugin (#613)
* Added WinNoCimSession switch to Windows plugin (#600) (Thanks @rhochmayr)
* Fix: Changing an order's PfxPass no longer shows the new value in Verbose output (#604)
* Fix: New-PACertificate no longer shows plaintext PfxPass in debug log (#604)
* Fixed a bug in `New-PACertificate` that would unnecessarily create a new order when an existing unfinished order could have been continued
* Fixed a couple minor bugs related to switching profiles when creating new orders that match existing orders.
* Fix: Added a workaround for non-compliant order response from GoDaddy's ACME implementation (#611)
* Fixed PowerDNS plugin when using limited API key that doesn't have access to all hosted zones (#617) (Thanks @joachimcarrein)
* Removed the Warning message when creating a new ACME account with no `-Contact` parameter.
'@

    }

}

}
