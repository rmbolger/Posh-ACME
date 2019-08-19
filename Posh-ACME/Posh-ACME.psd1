@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '3.6.0'
GUID = '5f52d490-68dd-411c-8252-828c199a4e63'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'ACMEv2 protocol client for generating certificates using Let''s Encrypt (or other ACMEv2 compliant CA)'
CompatiblePSEditions = @('Desktop','Core')
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('lib\BouncyCastle.Crypto.dll')

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Posh-ACME.Format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Get-DnsPluginHelp',
    'Get-DnsPlugins',
    'Get-KeyAuthorization',
    'Get-PAAccount',
    'Get-PAAuthorizations',
    'Get-PACertificate',
    'Get-PAOrder',
    'Get-PAServer',
    'Install-PACertificate',
    'Invoke-HttpChallengeListener',
    'New-PAAccount',
    'New-PACertificate',
    'New-PAOrder',
    'Publish-DnsChallenge',
    'Remove-PAAccount',
    'Remove-PAOrder',
    'Remove-PAServer',
    'Save-DnsChallenge',
    'Send-ChallengeAck',
    'Set-PAAccount',
    'Set-PAOrder',
    'Set-PAServer',
    'Submit-ChallengeValidation',
    'Submit-OrderFinalize',
    'Submit-Renewal',
    'Unpublish-DnsChallenge'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'LetsEncrypt','ssl','tls','certificates','acme','Linux','Mac'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-ACME/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-ACME'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
## 3.6.0 (2019-08-19)

* Added new DNS plugins
  * Domeneshop (Thanks @ornulfn)
  * Dreamhost (Thanks @jhendricks123)
  * EasyDNS (Thanks @abrysiuk)
  * FreeDNS (afraid.org)
* Added `Invoke-HttpChallengeListener` function (Thanks @soltroy). This runs a self-hosted web server that can answer HTTP challenges. Look for a wiki usage guide soon.
* Added `Remove-PAServer` function. Warning: This deletes all data (accounts, orders, certs) associated with an ACME server.
* Added `Install-PACertificate` function. This can be used to manually import a cert to the Windows cert store. (#159)
* Added support for Cloudflare's new limited access API Tokens. See usage guide for details.
* Added support for propagation polling with ClouDNS plugin. See usage guide for details.
* Fixed edge case zone finding bug with ClouDNS plugin.
* Fixed DOcean (Digital Ocean) plugin which broke because they now enforce a 30 sec TTL minimum on record creation.
* Fixed overly aggressive error trapping in OVH plugin. (#162)
* Fixed a typo in the OVH plugin usage guide.
* Fixed SkipCertificateCheck is no longer ignored when passing a PAServer object via pipeline to Set-PAServer.
* Fixed `Submit-ChallengeValidation` no longer tries to sleep when DnsSleep = 0.
* Some internal refactoring.
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
