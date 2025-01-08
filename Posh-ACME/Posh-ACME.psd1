@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.27.0'
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
## 4.27.0 (2025-01-08)

* New DNS Plugins
  * [INWX](https://www.inwx.de/) (Thanks @andreashaerter)
  * [EuroDNSReseller](https://www.eurodns.com/) Check the guide on this one. It's only currently usable by reseller partners of EuroDNS and not direct EuroDNS customers. (Thanks @zoryatix)
* Fixed WEDOS plugin to handle different response types for dns-domains-list API call (#579)
* Publish-Challenge and Unpublish-Challenge now strip trailing `.` chars from the RecordName they pass to plugins in order to make edge-case parsing more predictable.
* Added additional ARI related error handling in New-PAOrder to more gracefully handle problems with the `replaces` field. (#587)
* Added additional error handling in the config import process to better deal with unexpected config states. (#587)
* Fixed a bug in the plugin development guide code that suggests how to parse short names from a RecordName and ZoneName value. The bug wouldn't correctly parse the short name in FQDNs that contained more than one instance of the zone name. (#584)
* Fixed all of the plugins that had implemented the bugged short name parsing algorithm.
  * Active24
  * Aliyun
  * All-Inkl
  * Aurora
  * AutoDNS
  * Azure
  * BlueCat
  * Bunny
  * ClouDNS
  * Combell
  * Constellix
  * CoreNetworks
  * DMEasy
  * DNSPod
  * DNSimple
  * DOcean
  * DeSEC
  * Domeneshop
  * EasyDNS
  * Easyname
  * FreeDNS
  * Gandi
  * GoDaddy
  * Hetzner
  * IBMSoftLayer
  * ISPConfig
  * Infomaniak
  * Linode
  * Loopia
  * NameCom
  * NameSilo
  * Namecheap
  * OVH
  * OnlineNet
  * PointDNS
  * Porkbun
  * PortsManagement
  * Regru
  * Simply
  * SimplyCom
  * TencentDNS
  * TotalUptime
  * WEDOS
  * WebsupportSK
  * Windows
  * Yandex
'@

    }

}

}
