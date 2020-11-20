## 4.0.0-beta (2020-11-20)

There is a 3.x to 4.x [migration guide](https://github.com/rmbolger/Posh-ACME/wiki/4.x-FAQ#how-do-i-upgrade-from-3x) in the 4.x FAQ on the wiki. But no changes should be necessary for users with existing certs that are renewing using `Submit-Renewal` unless they were also using the `-NewKey` parameter which has been removed. Orders can now be configured to always generate a new private key using `Set-PAOrder -AlwaysNewKey`.

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
* BUYPASS_PROD and BUYPASS_TEST are now recognized shortcuts for the the buypass.com CA environments when you use `Set-PAServer`.
* ZEROSSL_PROD is now a recognized shortcut for the zerossl.com CA when you use `Set-PAServer`.
* Added tab completion for `DirectoryUrl` in `Set-PAServer`.
* Added `Quiet` parameter to `Get-PAServer` which will prevent warnings if the specified server was not found.
* `Remove-PAServer` will now throw a warning instead of an error if the specified server doesn't exist on disk.
* Orders can now be passed by pipeline to `Submit-ChallengeValidation` and `Submit-OrderFinalize`.
* ACME protocol web request details have been moved from Verbose to Debug output and cleaned up so they're easier to follow. Web requests made from plugins will still be in Verbose output for the time being.

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


## 3.18.1 (2020-11-12)

* Upgraded BouncyCastle to 1.8.8.2 for version parity with Az.KeyVault to prevent module load errors in PowerShell 6+
* Fixed DuckDNS plugin file locations in .NET 4.6 fork.

## 3.18.0 (2020-11-07)

* Added new DNS plugin [DuckDNS](https://www.duckdns.org/). Note that due to provider limitations, this plugin can only normally be used for certs with a single name unless you workaround the limitation with custom scripting. See the [usage guide](https://github.com/rmbolger/Posh-ACME/blob/master/Posh-ACME/DnsPlugins/DuckDNS-Readme.md) for details.
* Fixed an example in `Export-PAAccountKey` help.
* Added code to detect 4.x configs and gracefully revert in case folks need to downgrade after upgrading to 4.x when it comes out.

## 3.17.0 (2020-10-09)

* NOTE: Let's Encrypt is now [restricting](https://community.letsencrypt.org/t/issuing-for-common-rsa-key-sizes-only/133839) RSA private key sizes to 2048, 3072, and 4096 for certificates. But Posh-ACME will continue to allow custom key sizes which may still work with other certificate authorities. 
* `New-PAAccount` and `Set-PAAccount -KeyRollover` now have a `-KeyFile` parameter that can be used to import an existing private key instead of generating a new one from scratch.
* Added `Export-PAAccountKey` which can be use to export your ACME account private key as a standard Base64 encoded PEM file.
  * For Boulder-based CAs, this can be used to recover lost ACME account configurations if you run `New-PAAccount` with the `-KeyFile` parameter and specify the exported key.
* Updated Zonomi plugin to support alternative providers who use a compatible API. (#282)
* Fixed a bug in OVH plugin that would prevent TXT record deletion in some cases. (#283)
* Fixed a bug in many plugins that would prevent TXT record editing when the record name was also the zone root (#280) (Thanks @ShaBangBinBash)
* Fixed tutorial syntax error (#277) (Thanks @Leon99)
* Fixed errors in `Get-PAAuthorizations` when returned object has no 'expires' property. (#276) (Thanks @mortenmw)
* Changed bad nonce retry message from Debug to Verbose so people using PowerShell's transcript features will see it more easily.
* A generic platform value has been added to the user agent string the module sends with its ACME requests.
* Tests have been updated for use with Pester v5. Running them in a dedicated PowerShell process is recommended.

## 3.16.0 (2020-08-31)

* Added new DNS plugin [NameSilo](https://www.namesilo.com) (Thanks @rkone)
* Added Preferred Chain support
  * There is a new `-PreferredChain` parameter on `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder`.
  * For new or existing orders, you may select an alternate CA chain based on the Issuing CA subject name if alternate chains are offered by the CA.
  * Example: `-PreferredChain 'ISRG Root X1'`
* Fixed a bug with `Submit-Renewal` that wasn't properly using `-PluginArgs` and `-NoSkipManualDns` parameters when `-AllOrders` or `-AllAccounts` switches were also used (#266 #275). (Thanks @f-bader)
* deSEC plugin has added retry logic to address API throttling issues for certs with many names (#275).
* Fixed a bug with Azure plugin when using `AZCertPfx` authentication from Windows.

## 3.15.1 (2020-07-08)

* Fixed Route53 trying to load AWSPowerShell module when not installed (#263)

## 3.15.0 (2020-06-22)

* Added new DNS plugin [DomainOffensive](https://www.do.de) (Thanks @Armitxes)
* `New-PAAccount` now has `ExtAcctKID`, `ExtAcctHMACKey`, and `ExtAcctAlgorithm` parameters to support Certificate Authorities that require external account binding. Look for a guide in the wiki soon.
* Added support for the new AWS.Tools modules when using Route53.
* Added support for more restricted API permissions when using OVH. It's now possible to only grant write access to a specific list of zones or even individual TXT records. See the usage guide for details.
* Added pre-registration support for AcmeDns. See the usage guide for details.
* Fixed a bug with GoDaddy that prevented managing DNS-only hosted domains.

## 3.14.0 (2020-05-07)

* Added new DNS plugin [Hetzner](https://www.hetzner.de/) (Thanks @derguterat)
* Fix for Google DNS plugin to ignore private zones. (Thanks @timwsuqld)
* Fix for Azure usage guide for using existing access token. (Thanks @arestarh)
* Fix for RFC2136 plugin which makes it usable for records other than the root domain.

## 3.13.0 (2020-04-11)

* Added new DNS plugins
  * Akamai
  * DNSPod (Thanks @WiZaRd31337)
  * Loopia
  * PointDNS (Thanks @danielsen)
  * Reg.ru (Thanks @WiZaRd31337)
  * RFC2136
  * Selectel.ru (Thanks @WiZaRd31337)
  * Yandex (Thanks @WiZaRd31337)
* When creating a new order, chain.cer and fullchain.cer are now backed up along with the other files.
* Added a workaround for non-compliant ACME server Nexus CM (#227)
* Various usage guide corrections. (Thanks @webprofusion-chrisc)
* Fixed a bug where New-PACertificate required the `-Force` parameter if the previous order was deactivated.
* Fixed the dev install script to account for a redirected Documents folder.
* Minor changes to how Gandi plugin works to address potential edge case bugs.

## 3.12.0 (2019-12-10)

* `Set-PAOrder` now has `-DnsPlugin` and `-PluginArgs` parameters to allow changing plugins and associated credentials prior to a renewal operation.
* Upgraded BouncyCastle library to version 1.8.5.2 and renamed the DLL to avoid conflicts with older copies that may get installed into the .NET GAC by other software.
* ACME server errors returned during calls to `Revoke-PAAuthorization` are now non-terminating errors rather than warnings.
* Fixed bug where new orders created with `New-PACertificate` and no explicit plugin wouldn't get the Manual default if the account was already authorized for the included names.
* Fixed `Get-PAAuthorizations` when using explicit account reference
* Fixed datetime parsing issues on non-US culture environments (#208)
* Fixed errors thrown by `Submit-Renewal` when run against an order with a null DnsPlugin. A warning is now thrown instead.
* Fixed parameter binding error when using `-PluginArgs` with `Submit-Renewal`
* Fixed HurricanElectric guide's parameter references
* Fixed Azure tests

## 3.11.0 (2019-11-12)

* Added `Revoke-PAAuthorization` which enables revocation of identifier authorizations associated with an account.
* `Get-PAAuthorizations` now has an optional -Account parameter and better error handling.
* `Get-PAAuthorization` has been added as an alias for `Get-PAAuthorizations` to better comply with PowerShell naming standards. It will likely be formally renamed in version 4.x and the old name should be considered deprecated. This change should allow dependent scripts to prepare for that change in advance.
* `Install-PACertificate` now supports parameters to select the store name, location, and the exportable flag.
* Workaround for Boulder [issue](https://github.com/letsencrypt/boulder/issues/4540) that doesn't return JSON error bodies for old endpoints.
* Fixed bug creating new orders with a changed KeyLength value that was preventing the required new private key from being created.

## 3.10.0 (2019-11-06)

* Added new DNS plugin [HurricaneElectric](https://dns.he.net/)
* Azure plugin now supports certificate based authentication. See the [plugin guide](https://github.com/rmbolger/Posh-ACME/blob/master/Posh-ACME/DnsPlugins/Azure-Readme.md) for details. (#190)
* Setup examples in the Azure plugin guide now utilize the [Az](https://www.powershellgallery.com/packages/Az/3.0.0) module rather than the legacy AzureRm.* modules. (#189)
* Fix for "No order for ID" errors caused by recent Boulder changes that no longer return order details for expired orders. (#192)
* Fixed being unable to switch active orders if an error occurred trying to refresh the order details from the ACME server.
* Added additional guidance on renewals and deployment to the tutorial.

## 3.9.0 (2019-10-26)

* Added new DNS plugin [UnoEuro](https://www.unoeuro.com/) (Thanks @OrKarstoft)
* Fix for Cloudflare plugin not working properly when limited scope token didn't have at least read permissions to all zones on an account. To use an edit token with limited zone permissions, you must now also specify a secondary token with read permissions to all zones. See the [plugin guide](https://github.com/rmbolger/Posh-ACME/blob/master/Posh-ACME/DnsPlugins/Cloudflare-Readme.md) for details. (#184)
*  Fix for PropertyNotFound exception when imported plugin data is null or not the expected hashtable value (#182)

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

## 3.7.0 (2019-09-18)

* Submit-Renewal now has a PluginArgs parameter to make it easier to update plugin credentials without needing to create a new order from scratch. (Thanks @matt-FFFFFF)
* The FriendlyName parameter in New-PACertificate and New-PAOrder now defaults to the certificate's primary name instead of an empty string to avoid a Windows bug that can occur when installing the generated PFX files.
* Fixed Windows plugin issue when using WinZoneScope and not all zones have that scope (#168)
* Fixed an internal bug with Export-PACertFiles that luckily didn't cause problems due to PowerShell variable scoping rules.
* Fixed a typo in the Cloudflare guide examples. (Thanks @mccanney)

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

## 3.5.0 (2019-06-21)

* Added new DNS plugin for Simple DNS Plus (#149) (Thanks @alphaz18)
* Changed a bunch of "-ErrorAction SilentlyContinue" references to "Ignore" so we're not filling the $Error collection with junk.
* Fix for Boulder removing ID field from new account output.
* Fixed an issue in a number of plugins that could cause errors if the case of the requested record didn't match the server's zone case. (Thanks @Makr91)
* Fixed a bug with the Route53 plugin when used on PowerShell Core without the AwsPowerShell module installed.
* Fixed some typos in the OVH plugin usage guide examples (#147)

## 3.4.0 (2019-04-30)

* Added new DNS plugin for OVH (#79)
* Added ZoneScope support to Windows plugin (#134) (Thanks @dawe78)
* Fixed issue #139 with GCloud plugin prompting for GCKeyFile after upgrading to 3.3.0. Users affected by this issue will need to submit a new cert request to re-establish the GCloud plugin config.
* Fixed issue #140 with AcmeDns plugin losing registration data after upgrading to 3.3.0. Users affected by this issue will need to submit a new cert request to re-establish the AcmeDns plugin config and it will likely involve updating any CNAME records currently in use.

## 3.3.0 (2019-03-24)

* Route53 plugin now has IAM Role support if you're running Posh-ACME from within AWS. See plugin usage guide for details (#128)
* Dynu plugin migrated to v2 of the Dynu API
* Fixed DNSPlugin and DNSAlias arrays not getting expanded properly when the number of names in the cert didn't match the values in those arrays.
* Fixed validation bugs when using SAN certs with challenge aliases or multiple different plugins (#127) (Thanks @whbingham)
* Revamped serialization/deserialization for plugin arguments which should prevent accidentally creating parameter binding conflicts when switching between parameter sets for a particular plugin (#129).

## 3.2.1 (2019-03-04)

* Fix #122 to make sure private keys are imported properly when using `-Install`
* Improve error handling for duplicate public zones in Azure. (#125)
* Add tag based workaround for duplicate public zones in Azure. (#125)

## 3.2.0 (2019-01-22)

* Added new DNS plugin for name.com registrar (Thanks @ravensorb)
* Added additional argument completers for Account IDs, MainDomain, and KeyLength parameters
* The Posh-ACME config location can now be set by creating a `POSHACME_HOME` environment variable. The directory must exist and be accessible prior to importing the module. If you change the value of the environment variable, you need to re-import the module with `-Force` or open a new PowerShell session for the change to take effect.
* Added better error handling for cases where the config location is not writable.
* Get-PACertificate now returns null instead of throwing an error if the cert or associated order doesn't exist
* Fixed the ability to revoke a certificate after the associated order has expired
* Fix for #117 involving broken renewal processing on PowerShell Core in non-US locales
* Fixes for additional DateTime handling on PowerShell Core

## 3.1.1 (2018-12-22)

* Fixed typo in Route53 plugin that prevented finding the AwsPowershell module

## 3.1.0 (2018-12-16)

* The following plugins have added non-Windows OS support or extended their existing support. Check the plugin guides for details.
  * Azure
  * DNSimple
  * Infoblox
  * Linode
  * LuaDns
  * NS1
  * Route53
* Route53 plugin no longer requires AwsPowershell module when used with explicit keys. It will still use the module if it's installed.
* Added tab completion for plugin names with `Get-DnsPluginHelp`
* Fix #112 for Azure and errors with private zones and subscriptions with more than 100 zones

## 3.0.1 (2018-11-30)

* Fix for #110 `Submit-Renewal` with -AllOrders or -AllAccounts fails to renew orders with invalid status. (Thanks @jeffmnall!)
* Fix for #109 `New-PACertificate` throws an error if -DnsPlugin is not specified rather than defaulting to Manual. (Thanks @TiloGit!)
* Fix internal BouncyCastle to .NET private key conversions where key parameters may need padding. (Thanks @alexzorin and @webprofusion-chrisc!)

## 3.0.0 (2018-11-13)

* Potentially breaking changes
  * Many ACME protocol messages that previously used GET requests have been changed to POST-as-GET to comply with the latest ACME draft-16. Let's Encrypt already supports the new draft, but other ACME servers may not yet.
  * `CertIssueTimeout` param was removed from `New-PACertificate` and `Submit-OrderFinalize` because it wasn't actually being used properly in the former and doesn't seem necessary anymore.
* New Feature: Generate certs from an existing certificate request which can be useful for appliances that generate their own keys and CSRs. (Thanks @virot)
  * New `CSRPath` parameter on `New-PACertificate` and `New-PAOrder` that removes the need for `Domain`, `CertKeyLength`, `NewCertKey`, `OCSPMustStaple`, `FriendlyName`, `PfxPass`, and `Install` parameters when used. Most values will be extracted from the CSR.
  * Certs generated using this method will not have PFX files created because there is no private key.
  * Certs generated using this method can not be automatically installed to the Windows cert store because there are no PFX files.
* `Get-KeyAuthorization` now has `ForDNS` parameter which returns the actual TXT value necessary for the dns-01 challenge. (Thanks @chandan1001)
* Added new DNS plugins
  * IBMSoftLayer (IBM Cloud DNS)
  * AutoDNS (InternetX XML Gateway)
* Fix for some validation params not getting set properly on new instances of old orders
* Fix for Windows plugin not using `$dnsParams` appropriately (Thanks @B4dM4n)

## 2.9.1 (2018-10-26)

* Fix (#94) for TXT record cleanup bug when some domains were already validated (Thanks @philr!)
* Fix (#95) error handling in New-PACertificate and New-PAOrder that would mistakenly cause new orders to be created if there were problems checking old orders. (Thanks @philr!)
* Azure fix (#96) to allow special characters in credentials. (Thanks @philr!)
* Route53 fix for errors caused by public/private zones with same name (#100) (Thanks @spaceygithub!)

## 2.9.0 (2018-10-05)

* Added new DNS plugins
  * BlueCat (Thanks @marshallford)
  * Gandi
* Updated DMEasy plugin to support non-Windows

## 2.8.0 (2018-09-12)

* Added new DNS plugins
  * Aliyun (Alibaba Cloud)
  * DeSEC (Thanks @nazar554)
* Fix for type error when using OCSP Must-Staple (Thanks @casselc)
* Parameter binding bug fixes for Azure and Windows plugins (Thanks @mithrandyr)

## 2.7.1 (2018-08-30)

* Removed ACMEv2 draft-12 support for account key rollover. No known CAs are still implementing draft-12.
* Fix for issue #53 with GoDaddy plugin not being able to remove TXT records in some cases. Thanks @davehope!
* Performance and efficiency improvements with GoDaddy plugin
* Fixed Get-PACertificate -List only showing certs from 'valid' orders.

## 2.7.0 (2018-08-12)

* Added new DNS plugin ClouDNS
* Added ACMEv2 draft-13 support for account key rollover. This is an interim fix that should still work with draft-12 as well. Once Let's Encrypt goes into production with draft-13, the draft-12 support will be removed.
* .NET version check now throws a warning instead of error on module load
* Fixed Get-PAAccount not filtering contacts correctly
* Minor fix and help correction in Namecheap plugin
* Get-PAAccount and Get-PAOrder now return null instead of an error if an invalid account or order was specified. (Thanks for the idea @maybe-hello-world)

## 2.6.0 (2018-08-01)

* Added additional functions that should make it easier to manually respond to challenges. In particular, this should allow people to use the HTTP challenge until a formal HTTP challenge plugin solution is introduced. (Thanks John B. for the idea!)
  * `Get-KeyAuthorization` calculate a key authorization string for a challenge token.
  * `Send-ChallengeAck` notifies the ACME server to proceed validating a challenge.
  * The output object on `Get-PAAuthorizations` now contains top level attributes relating to the HTTP challenge (in addition to the existing DNS challenge).
* Added new DNS plugins
  * Namecheap
  * Rackspace
* Migrated all internal DateTime handling to use DateTimeOffset which is less finicky across time zones for the types of comparisons generally being performed.


## 2.5.0 (2018-07-12)

* Added new DNS plugin Dynu. (Thanks @alexzorin!)
* Added additional Azure plugin authentication options including explicit access token and Instance Metadata Service support. See plugin readme for details. (Thanks @perbergland!)
* Added an explicit .NET 4.7.1 version check on module load when running Windows PowerShell (Desktop edition) since the module manifest didn't seem to be enforcing it. This will throw an error if you try to import the module without at least .NET 4.7.1 installed and hopefully prevent bug reports due to insufficient .NET versions.
* Fixed bug with GoDaddy plugin (#50) that prevented using names in sub-domains. (Thanks @davehope!)
* Fixed bug with Azure plugin (#57) incorrectly evaluating token expiration. (Thanks @Cavorter!)
* Fixed bug (#60) that would cause some order parameters to appear to get wiped when renewing or creating a new order whose names had already been validated. (Thanks for the tip @hutch120!)
* Various readme tweaks

## 2.4.0 (2018-06-01)

* Added new DNS plugin Linode
* Added tab completion for `Plugin` param on `Publish`/`Unpublish`/`Save-DnsChallenge`
* Fixed bug renewing orders with status invalid (which happens when the order expires even if the cert is still valid)
* Fixed bug in `New-PACertificate` that wasn't using explicit `DnsSleep` and `ValidationTimeout` parameters when an old order existed for the same primary name.

## 2.3.0 (2018-05-29)

* Added new DNS plugins
  * DNSimple
  * LuaDns
  * NS1
* Challenge validation errors will now show the detailed error message provided by the ACME server
* Get-PAAuthorization will now throw a warning instead of errors for expired authorizations
* Fixed bug with Infoblox plugin
* Fixed error with Get-PACertificate on orders created prior to 2.0
* Misc fixes for plugin help details

## 2.2.0 (2018-05-24)

* Added cross platform PowerShell Core support!
  * Some DNS plugins don't work yet on non-Windows due to known issue handling SecureString PowerShell Core 6.0. Check details on the project wiki.
  * `-Install` param on `New-PACertificate` throws error on non-Windows because there's no certificate store to install to.
  * `Windows` plugin doesn't work in Core at all yet due to lack of Core compatible DnsServer module.
* Added new DNS plugin Zonomi. Thanks @Zippy79!

## 2.1.1 (2018-05-19)

* Fix for GCloud plugin syntax error

## 2.1.0 (2018-05-18)

* Added account key rollover support. Use -KeyRollover switch in Set-PAAccount.
* Added PfxPass (SecureString) to Get-PACertificate output
* Added new DNS plugins
  * DMEasy (DNS Made Easy)
  * GoDaddy. Thanks @Rukas!
* All calls to Invoke-WebRequest and Invoke-RestMethod now use -UseBasicParsing to avoid issues with PowerShell using Internet Explorer's DOM parser. Thanks @Rukas!
* Fixed hard coded cert store paths in Import-PfxCertInternal
* Fixed tests for New-Jws

## 2.0.1 (2018-05-12)

* Fix for PluginArgs not being passed to Submit-ChallengeValidation. Thanks @juliansiebert!
* Fix for Azure plugin when multiple zones are in a subscription. Thanks @juliansiebert!

## 2.0 (2018-05-12)

* Potentially Breaking Changes
  * New-PACertificate now outputs certificate details to the pipeline which should aid automation
  * New-PACertificate now reuses all previous order params (for the same MainDomain) when not explicitly specified
  * All generated PFX files now have 'poshacme' as the default password to address compatibility issues with other tools
* New-PACertificate now generates fullchain.pfx in addition to cert.pfx
* Added optional parameters to New-PACertificate
  * `-FriendlyName` sets Friendly Name when imported into Windows certificate store
  * `-PfxPass` overrides the default password for generated PFX files
  * `-Install` switch imports fullchain.pfx to Windows certificate store. *Requires elevation*
* Added new DNS plugins
  * DOcean (Digital Ocean)
  * Cloudflare. Thanks @rian-hout!
* Added Get-PACertificate which returns certificate details
* Added usage guides for most DNS plugins
* Added progress bar while waiting for DNS changes to propagate
* Old csr and chain files are no longer backed up when creating a new order
* Manual plugin now displays all records to create with one prompt
* Fixed AcmeDns plugin issue where CNAMEs would display twice user Ctrl-C from prompt
* Bugfix for Azure plugin (#17). Thanks @juliansiebert!
* New-PACertificate will no longer redownload certs when run with same arguments (#9)

## 1.1 (2018-05-02)

* Added tab completion for -DnsPlugin parameter
* Added new DNS plugins
  * Acme-Dns
  * Azure
  * GCloud (Google Cloud)
  * Windows

## 1.0 (2018-04-27)

* Initial Release
* Added functions
  * Get-DnsPluginHelp
  * Get-DnsPlugins
  * Get-PAAccount
  * Get-PAAuthorizations
  * Get-PAOrder
  * Get-PAServer
  * New-PAAccount
  * New-PACertificate
  * New-PAOrder
  * Publish-DnsChallenge
  * Remove-PAAccount
  * Remove-PAOrder
  * Save-DnsChallenge
  * Set-PAAccount
  * Set-PAOrder
  * Set-PAServer
  * Submit-ChallengeValidation
  * Submit-OrderFinalize
  * Submit-Renewal
  * Unpublish-DnsChallenge
