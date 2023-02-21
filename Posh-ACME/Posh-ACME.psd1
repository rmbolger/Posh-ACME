@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.17.0'
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
## 4.17.0 (2023-02-20)

* New DNS plugins
  * [Google Domains](https://domains.google/) This should be considered experimental while the Google Domains ACME API is still in testing. (Thanks @webprofusion-chrisc)
  * [IONOS](https://www.ionos.de/) (Thanks @RLcyberTech)
  * SSHProxy sends update requests via SSH to another server which is able to do dynamic updates against your chosen DNS provider. (Thanks @bretgiddings)
* The `DDNSNameserver` parameter is no longer mandatory in the RFC2136 plugin which will make nsupdate try to use whatever primary nameserver is returned from an SOA query.
* Added Basic authentication support to the AcmeDns plugin which should allow it to be used against endpoints that enforce that such as [Certify DNS](https://docs.certifytheweb.com/docs/dns/providers/certifydns/).
* Added support for plugin parameters that are arrays of SecureString or PSCredential objects.
* Fixed PAServer switches getting reset on `Set-PAServer` with no params (#475)
'@

    }

}

}
