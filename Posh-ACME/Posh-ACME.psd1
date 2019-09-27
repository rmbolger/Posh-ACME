@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '3.8.0'
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
    'Get-DnsPluginHelp'
    'Get-DnsPlugins'
    'Get-KeyAuthorization'
    'Get-PAAccount'
    'Get-PAAuthorizations'
    'Get-PACertificate'
    'Get-PAOrder'
    'Get-PAServer'
    'Install-PACertificate'
    'Invoke-HttpChallengeListener'
    'New-PAAccount'
    'New-PACertificate'
    'New-PAOrder'
    'Publish-DnsChallenge'
    'Remove-PAAccount'
    'Remove-PAOrder'
    'Remove-PAServer'
    'Save-DnsChallenge'
    'Send-ChallengeAck'
    'Set-PAAccount'
    'Set-PAOrder'
    'Set-PAServer'
    'Submit-ChallengeValidation'
    'Submit-OrderFinalize'
    'Submit-Renewal'
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
## 3.8.0 (2019-09-27)

* `Set-PAOrder` now supports modifying some order properties such as FriendlyName, PfxPass, and the Install switch that don't require generating a new ACME order. FriendlyName or PfxPass changes will regenerate the current PFX files with the new value(s) if they exist. Changes to the Install switch will only affect future renewals.
* Fixed FriendlyName, PfxPass, and Install parameters not applying when calling `New-PACertificate` against an existing order (#178)
* Fixed GoDaddy plugin so it doesn't fail on large accounts (100+ domains) (#179)
* Updated Cloudflare plugin to workaround API bug with limited scope tokens (#176)
* Fixed DnsSleep and ValidationTimout being null when manually creating an order with `New-PAOrder` and finishing it with `New-PACertificate`.
* Added parameter help for -NewKey on `New-PAOrder` which was missing.
* When using `New-PACertificate` against an already completed order that is not ready for renewal, the informational message has been changed to Warning from Verbose to make it more apparent that nothing was done.
* Updated `instdev.ps1` so it still works when the BouncyCastle DLL is locked and $ErrorActionPreference is set to Stop.
* Updated a bunch of plugin guides with info regarding PowerShell 6.2's fix for the SecureString serialization bug and enabling the use of secure parameter sets on non-Windows.
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
