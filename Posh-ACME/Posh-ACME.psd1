@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.15.0'
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
## 4.15.0 (2022-08-26)

* PAOrder objects now have a flag to optionally use modern encryption options on generated PFX files. This will prevent the need to use "legacy" mode when reading the files with OpenSSL 3.x. However, it breaks compatibility with OpenSSL 1.0.x and earlier.
  * You can use the `-UseModernPfxEncryption` flag with `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder`. When used with `Set-PAOrder`, existing PFX files will be re-written based on the flag's new value.
  * Use `Set-PAOrder -UseModernPfxEncryption:$false` to switch back to the default setting.
  * The default for new orders will likely remain off until Posh-ACME 5.x is released.
* Added new DNS plugin [PortsManagement](https://portsgroup.com/) (Thanks @wemmer)
* The GCloud plugin has a new optional parameter, `GCProjectId` that takes one or more string values. This is only required if the DNS zones to modify don't reside in the same project as the service account referenced by `GCKeyFile` or they reside in multiple projects. When used, be sure to include all project IDs including the one referenced by `GCKeyFile`.
* Added Google's new free ACME CA to the CA comparison doc
* Upgraded the embedded BouncyCastle library to 1.9.0
* Fixed UKFast plugin to support paging for accounts with many domains (Thanks @0x4c6565)
* Fixed PFX friendly name generation when not provided in the order.
'@

    }

}

}
