@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.11.0'
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
## 4.11.0 (2021-11-24)

* Added [SecretManagement](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/) support! See [this guide](https://poshac.me/docs/v4/Guides/Using-SecretManagement/) for details.
* Added new DNS plugins:
  * [Combell](https://www.combell.com/) (Thanks @stevenvolckaert)
  * [TotalUptime](https://totaluptime.com/solutions/cloud-dns-service/) (Thanks @CirotheSilver)
* `Install-PACertificate` and the `-Install` switch on orders will now import associated chain certificates into the Intermediate cert store if they don't already exist. (#397)
* `New-PAOrder` will now throw an error if the order object returned by the ACME server matches an existing order with a different name. (#401)
* The progress bar for DNS propagation is now disabled by default unless a POSHACME_SHOW_PROGRESS environment variable is defined. A verbose message will be written once per minute as an alternative. (#402)
* Added auth token caching to CoreNetworks plugin to avoid getting rate limited. (#403)
* Fixed ISPConfig plugin throwing Incorrect datetime value errors when adding records (#404)
* Fixed a bug with `Submit-Renewal -AllAccounts` that would prevent restoring the original active account. (Thanks @markpizz) (#395)
* Fixed usage example in EasyDns guide. (Thanks @webprofusion_chrisc) (#407)
'@

    }

}

}
