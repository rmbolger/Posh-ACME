@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.6.0'
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
## 4.6.0 (2021-07-25)

* Added new DNS plugins
  * [HostingDe](https://hosting.de/)
  * [Beget](https://beget.com/)
* Revoke-PACertificate no longer requires a configured account when using an explicit cert/key (#361)
* Fixed Aurora plugin for edge case bug with PowerShell Core (#353)
* Fixed DirectoryUrl completers in PS 5.1 when no servers currently exist.
* Fixed unauthenticated updates with RFC2136 plugin (#360) (Thanks @dsbibby)
* Refactored Simply plugin to be IDN agnostic and redact API keys from logging (#352)
* ACME errors from New-PAAccount should be less ugly now.
'@

    }

}

}
