@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.7.0'
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
## 4.7.0 (2021-08-24)

* Servers, Accounts, and Orders all now have configurable Names that also determine the name of their associated folders in the config on the filesystem. (#345) This is a fairly large change, but significant effort has been spent implementing it so that dependent scripts will not break.
  * **Please backup your current config before customizing your object names.** Previous Posh-ACME versions will break trying to read configs with custom names.
  * All customized names may only use the following characters to avoid cross-platform filesystem compatibility issues: `0-9 a-z A-Z - . _ !`.
  * A `NewName` parameter has been added to `Set-PAServer`, `Set-PAAccount`, and `Set-PAOrder` to change the name of each type of object.
  * Server related functions now have an optional `Name` parameter which can be used instead of or in addition to the `DirectoryUrl` parameter. This includes `Get/Remove/Set-PAServer`.
  * If a server doesn't already exist, `Set-PAServer` will use the `-Name` parameter for the new server's name. If the server already exists, it is ignored.
  * Returned server objects now have `Name` and `Folder` properties.
  * Despite being able to customize Server names, you may still only have a single instance of each unique ACME server in your config. This may chang in a future major version.
  * Account related functions that have an `ID` parameter now have a `Name` parameter alias. This includes `Get/Remove/Set-PAAccount` and `Export-PAAccountKey`. The ID parameter should be considered deprecated and in future major versions will be replaced by `Name`.
  * The `ID` parameter was added to `New-PAAccount` to allow setting the customized ID on creation instead of using the server provided default value.
  * Returned account objects now have a `Folder` property and the `id` property now reflects the customizable value.
  * The `id` property on account objects is deprecated and will be changed to `Name` in a future major version.
  * Order related functions now have an optional `Name` parameter to distinguish between multiple orders that may have the same `MainDomain`. This includes `Get/Revoke/New-PACertificate`, `Get/New/Set/Remove-PAOrder`, `Get-PAPluginArgs`, `Invoke-HttpChallengeListener`, and `Submit-Renewal`. In most cases, the `Name` parameter can also be used by itself as a unique identifier for orders.
  * The `Name` parameter on `New-PACertificate` and `New-PAOrder` allows setting the customized order name on creation instead of using the MainDomain default value.
  * Returned order objects now have a `Name` property (not to be confused with `FriendlyName` which only affects the certificate associated with the order).
  * Order related error and log messages that previously mentioned the order's MainDomain have been changed to use the order's Name instead.
  * To retain backwards compatibility with existing 4.x dependent scripts, `Get-PAOrder` will return the single, most recent order when used with `-MainDomain` even if there are multiple matching orders. This also affects `Get-PACertificate` which uses Get-PAOrder under the hood.
  * `Set-PAOrder`, `Revoke-PACertificate`, and `Remove-PAOrder` will throw an error if only `MainDomain` is specified and it matches multiple orders. Specify the `Name` parameter as well to ensure a unique order match.
* Custom plugins can now be loaded from an alternate filesystem location by creating a `POSHACME_PLUGINS` environment variable before the module is loaded. The value should be a folder path that contains uniquely named .ps1 plugin files. If any custom plugins have the same name as native plugins, a warning will be thrown and they will not be loaded.
* Added `New-PAAuthorization` which allows the creation of authorization objects outside the context of an order. NOTE: BuyPass is the only free ACME CA that currently supports this feature.
* Added a `OnlyReturnExisting` parameter to `New-PAAccount` when using an imported key which instructs the ACME server to only return account details if an account already exists for that key.
* Added a `NoSwitch` parameter to `Set-PAServer` so you can modify the active server without switching to it.
* The `AllSANs` field on PACertificate objects now reflects the SAN list on the actual certificate instead of its associated ACME order (just in case the two lists have divered for some strange reason).
* Added missing help on `Get-PAPluginArgs`.
* Default formatting for PAServer objects has been tweaked to show more useful info.
* Default formatting for PAOrder object now includes `Name` and has removed `OSCPMustStaple`.
* The `Quiet` parameter has been removed from the `Get-PAServer -List` parameter set because it didn't make sense.
* Fixed an example in `Remove-PAServer` help.
* Added workaround for BuyPass bug that prevents some error details from being parsed.
* Adjusted support for Account Key Rollover to more closely follow RFC8555 which fixes a bug using it with BuyPass
* Changed some logic in `Revoke-PACertificate` so that it works with BuyPass which doesn't seem to support revocation using the cert's private key.
* Orders using an ECC private key will no longer include Key Encipherment in the CSR's keyUsage when submitting an order for finalization. Key Encipherment is not supported for ECDSA certs and some CAs were rejecting the finalization.
'@

    }

}

}
