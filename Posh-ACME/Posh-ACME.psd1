@{

RootModule = 'Posh-ACME.psm1'
ModuleVersion = '4.0.0'
GUID = '5f52d490-68dd-411c-8252-828c199a4e63'
Author = 'Ryan Bolger'
Copyright = '(c) 2018 Ryan Bolger. All rights reserved.'
Description = 'ACMEv2 protocol client for generating certificates using Let''s Encrypt (or other ACMEv2 compliant CA)'
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
## 4.0.0 (2020-12-18)

There is a 3.x to 4.x [migration guide](https://github.com/rmbolger/Posh-ACME/wiki/Frequently-Asked-Questions-%28FAQ%29#how-do-i-upgrade-from-3x-to-4x) in the FAQ on the wiki. But no changes should be necessary for users with existing certs that are renewing using `Submit-Renewal` unless they were also using the `-NewKey` parameter which has been removed. Orders can now be configured to always generate a new private key using `Set-PAOrder -AlwaysNewKey`.

### New Features

* The DNS plugin system has been revamped to support both dns-01 and http-01 challenges. (#124)
  * All existing DNS plugins have been upgraded to the new plugin format. See the README in the plugins folder for details and instructions on how to upgrade your own custom plugins.
  * There are two new http-01 challenge plugins called `WebRoot` and `WebSelfHost`. See their usage guides for details.
* Plugin args are now saved per-order rather than per-account and as JSON rather than XML.
  * This has the side effect that new orders using the same plugin(s) as a previous order will no longer reuse the previous args.
  * Added `Get-PAPluginArgs` which returns a hashtable with the plugin args associated with the current or specified order. You can use this to retrieve another order's plugin args and use that object with your new order.
  * Pre-4.x plugin args will be automatically migrated to per-order plugin args the first time an account is selected using `Set-PAAccount` or on module load for the last selected account. The old file will be backed up with a ".v3" extension in case you need to revert.
* Portable, Cross-Platform encryption is now supported for secure plugin parameters on disk and can be configured on a per-account basis. It is based on a 256-bit AES key generated for the account. This makes it possible to migrate a Posh-ACME config between users, machines, or OSes without needing to re-configure secure plugin args. (#150)
  * To enable, set the `UseAltPluginEncryption` switch on `New-PAAccount` or `Set-PAAccount`. This will immediately re-encrypt plugin args for all orders associated with the account.
  * To disable/revert, run `Set-PAAccount -UseAltPluginEncryption:$false`.
  * If you believe the encryption key has been compromised, use `Set-PAAccount -ResetAltPluginEncryption` to generate a new key and re-encrypt everything.
* `Get-PAPlugin` is a new function that replaces `Get-DnsPlugins` and `Get-DnsPluginHelp`.
  * With no parameters, lists all plugins and their details
  * With a plugin parameter, shows the details for just that plugin
  * With a plugin and `-Help`, shows the plugin's help
  * With a plugin and `-Guide`, opens the default browser to the plugin's online guide
  * With a plugin and `-Params`, displays the plugin-specific parameter sets (#151)
* Added `AlwaysNewKey` switch to `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder`. This flag tells Posh-ACME to always generate a new private key on renewals. The old parameters for key replacement have been removed. (#181)
* Added `UseSerialValidation` switch to `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder`. This flag tells Posh-ACME to process the order's authorization challenges serially rather than in parallel. This is primarily useful for providers like DuckDNS that only allow a single TXT record to be written at a time.
* Added `Complete-PAOrder` which does the final processing steps like downloading the signed cert and updating renewal window for an order that has reached the 'ready' state. This avoids the need to use `New-PACertificate` when doing custom certificate workflows.
* The PfxPass parameter on order objects is now obfuscated when serialized to disk. (#207)
* Added `PfxPassSecure` (SecureString) parameter to `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder` which takes precedence over `PfxPass` if specified. (#207)
* Added `DnsAlias` and `OCSPMustStaple` parameters to `Set-PAOrder`. Changing an order's OCSPMustStaple value will throw a warning that it only affects future certificates generated from the order.
* Added `Plugin`, `PluginArgs`, `DnsAlias`, `DnsSleep`, and `ValidationTimeout` parameters to `New-PAOrder`.
* The `DirectoryUrl` parameter in `Set-PAServer` is now optional. If not specified, it will use the currently active server.
* An attempt will now be made to send anonymous telemetry data to the Posh-ACME team when `Submit-OrderFinalize` is called directly or indirectly.
  * The only data sent is the standard HTTP User-Agent header which includes the Posh-ACME version, PowerShell version, and generic OS platform (Windows/Linux/MacOS/Unknown).
  * This can be disabled per ACME server using a new `DisableTelemetry` parameter in `Set-PAServer`.
  * The data will be used to guide future development decisions in the module.
  * The same User-Agent header is also sent with all calls to the ACME server which is a requirement of the protocol and can't be disabled.
* Added `NoRefresh` switch to `Set-PAServer` which prevents a request to the ACME server to update endpoint and nonce info. This is useful for updating local preferences without making a server round-trip.
* BUYPASS_PROD and BUYPASS_TEST are now recognized shortcuts for the the buypass.com CA environments when you use `Set-PAServer`.
* ZEROSSL_PROD is now a recognized shortcut for the zerossl.com CA when you use `Set-PAServer`.
* Added tab completion for `DirectoryUrl` in `Set-PAServer`.
* Added `Quiet` parameter to `Get-PAServer` which will prevent warnings if the specified server was not found.
* `Remove-PAServer` will now throw a warning instead of an error if the specified server doesn't exist on disk.
* Orders can now be passed by pipeline to `Submit-ChallengeValidation` and `Submit-OrderFinalize`.
* ACME protocol web request details have been moved from Verbose to Debug output and cleaned up so they're easier to follow. Web requests made from plugins will still be in Verbose output for the time being.
* Experimental support for IP address identifiers ([RFC 8738](https://tools.ietf.org/html/rfc8738)) in new orders. This allows you to get a cert for an IP address if your ACME server supports it.
* Private keys for Accounts and Certificates can now use ECC P-521 (secp521r1) based keys using the `ec-521` key length parameter. *This requires support at the ACME server level as well.*

### Breaking Changes

* Function Changes
  * `Publish-DnsChallenge` is now `Publish-Challenge`
  * `Unpublish-DnsChallenge` is now `Unpublish-Challenge`
  * `Save-DnsChallenge` is now `Save-Challenge`
  * `Get-DnsPlugins` and `Get-DnsPluginHelp` have been replaced by `Get-PAPlugin`
  * `Get-PAAuthorizations` is now `Get-PAAuthorization`. The plural function name is still avaialble as an alias but is deprecated and may be removed in a future release.
  * `Invoke-HttpChallengeListener` is deprecated and may be removed in a future release. Users should migrate to the `WebSelfHost` plugin.
* Parameter Changes
  * All `DnsPlugin` parameters are now `Plugin` with a `DnsPlugin` alias for backwards compatibility. The alias should be considered deprecated and may be removed in a future release.
  * The `NoPrefix` switch in Publish/Unpublish-Challenge has been replaced with a `DnsAlias` parameter that will override the `Domain` parameter if specified. "_acme-challenge." will not be automatically added to the `DnsAlias` parameter.
  * `NewKey` has been removed from `Submit-Renewal`
  * `NewKey`/`NewCertKey` have been replaced by `AlwaysNewKey` in `New-PACertificate` and `New-PAOrder`
  * `AlwaysNewKey` has been added to `Set-PAOrder`
  * `DnsPlugin`, `PluginArgs`, `DnsAlias`, `DnsSleep`, `ValidationTimeout` and `Account` parameters have been removed from `Submit-ChallengeValidation`. The account associated with the order must be the currently active account. The rest of the parameters are read directly from the order object and can be modified in advance with `Set-PAOrder` if necessary.
  * `Account` parameter has been removed from `Submit-OrderFinalize`. The account associated with the order must be the currently active account.

### Fixes

* Using `Get-PAOrder` with `-Refresh` will no longer throw a terminating error if the ACME server returns an error. It will warn and return the cached copy of the order instead.
* Fixed `Remove-PAServer` not being able to remove a server that is unreachable.
* `Remove-PAServer` no longer requires confirmation when there are no cached accounts associated with the specified server in the local config.
'@

    }

}

}
