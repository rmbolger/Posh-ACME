@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.3.0'
GUID = '5f52d490-68dd-411c-8252-828c199a4e63'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'ACME protocol client for obtaining certificates using Let''s Encrypt (or other ACME compliant CA)'
CompatiblePSEditions = @('Desktop','Core')
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.1'

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('lib\BC.Crypto.1.8.8.2-netstandard2.0.dll')

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
    'Publish-Challenge'
    'Remove-PAAccount'
    'Remove-PAOrder'
    'Remove-PAServer'
    'Revoke-PAAuthorization'
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
## 4.3.0 (2021-02-24)

* PreferredChain selection logic has been updated to consider "distance from root" as a way to break ties when the specified CA subject is found in multiple chains. Chains with the CA closer to the root take precedence over ones with it further away. (#315)
* `CFTokenReadAll` and `CFTokenReadAllInsecure` have been removed from the Cloudflare plugin because they are no longer needed. Cloudflare fixed the API bug that made them necessary when using edit tokens scoped to a specific zone or zones. No user action is required if you were previously using these parameters. They will simply be ignored.
* HTTP call detail has been changed from Verbose to Debug output in Cloudflare and Route53 plugins.
* Fixed CSR handing for CSRs that have no attributes (#317) (Thanks @methorpe)
* Fixed Route53 plugin compatibility with older versions of the AWSPowerShell module (#318)

### Deprecation Notice

Many plugins have optional parameter sets that use "Insecure" versions of the primary SecureString or PSCredential parameters due to bugs in early versions of PowerShell 6 that prevented using them on non-Windows OSes. Those bugs have been fixed since PowerShell 6.2 and the insecure parameter sets should be considered deprecated and will likely be removed in the next major version (5.x) of Posh-ACME. Individual plugin usage guides will slowly be updated over the course of 4.x to warn about the specific parameter deprecations.
'@

    }

}

}
