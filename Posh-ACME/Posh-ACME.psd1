@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '2.0'
GUID = '5f52d490-68dd-411c-8252-828c199a4e63'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'ACMEv2 protocol client for generating certificates using Let''s Encrypt (or other ACMEv2 compliant CA)'
CompatiblePSEditions = 'Desktop'
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
    'Get-PAAccount',
    'Get-PAAuthorizations',
    'Get-PACertificate',
    'Get-PAOrder',
    'Get-PAServer',
    'New-PAAccount',
    'New-PACertificate',
    'New-PAOrder',
    'Publish-DnsChallenge',
    'Remove-PAAccount',
    'Remove-PAOrder',
    'Save-DnsChallenge',
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
        Tags = 'LetsEncrypt','ssl','tls','certificates','acme','powershell'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-ACME/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-ACME'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
## 2.0 (2018-05-12)

* Potentially Breaking Changes
  * New-PACertificate now outputs certificate details to the pipeline which should aid automation
  * New-PACertificate now reuses all previous order params (for the same MainDomain) when not explicitly specified
  * All generated PFX files now have 'poshacme' as the default password to address compatibility issues with other tools
* Added optional parameters to New-PACertificate
  * `-FriendlyName` sets Friendly Name when imported into Windows certificate store
  * `-PfxPass` overrides the default password for generated PFX files
  * `-Install` switch imports cert to Windows certificate store. *Requires elevation*
* Added new DNS plugins
  * DOcean (Digital Ocean)
  * Cloudflare. Thanks @rian-hout!
* Added Get-PACertificate which returns certificate details
* New-PACertificate now generates fullchain.pfx in addition to cert.pfx
* Added usage guides for most DNS plugins
* Added progress bar while waiting for DNS changes to propagate
* Old csr and chain files are no longer backed up when creating a new order
* Manual plugin now displays all records to create with one prompt
* Fixed AcmeDns plugin issue where CNAMEs would display twice user Ctrl-C from prompt
* Bugfix for Azure plugin (#17). Thanks @juliansiebert!
* New-PACertificate will no longer redownload certs when run with same arguments (#9)
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
