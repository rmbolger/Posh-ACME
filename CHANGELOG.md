## 4.30.0 (2025-11-13)

* New [HetznerCloud](https://www.hetzner.com/) plugin (#642) (Thanks @humnose)
  * This is for Hetzner users who have migrated their zones from the legacy "DNS Console" to the new "Hetzner Console". NOTE: New API tokens are needed.
* Added `AZArcAgentAPIVersion` param for Azure IMDS parameter set (#636) (Thanks @semics-tech)
  * This may be necessary systems running older versions of the Azure Managed Identity Agent that don't work with the default version identifier.
* Added `ACTALIS_PROD` to the list of well-known directory shortcuts. They've also been added to the ACME CA Comparison guide.
* Removed `BUYPASS_PROD` and `BUYPASS_TEST` from the list of well-known directory shortcuts since they are no longer in operation.
* Removed a workaround for a BuyPass server bug which is no longer necessary.
* Fixed Windows plugin breaks when not using WinUseSsl or WinSkipCACheck switches (#637) (Thanks @jmpederson1)
* Fixed PS 5.1 compat with DeSEC and EuroDNSReseller by removing -Depth param from ConvertFrom-Json calls (#643)
* Fixed null ref errors in CoreNetworks plugin when no matching zone found. Added additional debug logs. (#616)

## 4.29.3 (2025-07-24)

* The current ACME server directory endpoint is now refreshed on module import to ensure server changes are reflected before actions are performed. If the previously used ACME server is unreachable, a warning is thrown and previously cached data is used.
  * This should fix anyone who is getting 404 errors when renewing Let's Encrypt certs due to an unannounced change to their ARI endpoint. Users can also fix this problem without upgrading by running `Get-PAServer -Refresh`.

## 4.29.2 (2025-07-15)

* Fixed param set resolution error with New-PACertificate when using CSRPath/CSRString params (#629)
* Added workaround for non-compliant order response from KeyFactor ACME provider (#626)
* Added additional logging to DuckDNS plugin (#628)
* Tweaked debug output for ACME responses for better human readability

## 4.29.1 (2025-06-26)

* Fix Route53 plugin when used with AWS Tools for PowerShell 5.x (#627)

## 4.29.0 (2025-06-25)

* New DNS Plugins
  * [Netcup](https://www.netcup.com) (#602)
  * [TransIP](https://www.transip.nl) (#622) (Thanks @Tim81)
* Added `-IgnoreContact` switch to `Set-PAServer` (#619)
  * ALL USERS of LET'S ENCRYPT, this switch works around a bug that causes a new account to be created for every renewal after LE shut down their automated email warning service.
  * This option causes the module to ignore any `-Contact` parameters in functions that support it when using the associated server.
  * It will be enabled by default on new installs that use Let's Encrypt. But existing users will need to manually enable it *OR* simply stop using the `-Contact` parameter in your scripts when using Let's Encrypt ACME endpoints.
* Added AZAccessTokenSecure param for Azure plugin (#618)
* Added WinSkipCACheck switch to Windows plugin (#613)
* Added WinNoCimSession switch to Windows plugin (#600) (Thanks @rhochmayr)
* Fix: Changing an order's PfxPass no longer shows the new value in Verbose output (#604)
* Fix: New-PACertificate no longer shows plaintext PfxPass in debug log (#604)
* Fixed a bug in `New-PACertificate` that would unnecessarily create a new order when an existing unfinished order could have been continued
* Fixed a couple minor bugs related to switching profiles when creating new orders that match existing orders.
* Fix: Added a workaround for non-compliant order response from GoDaddy's ACME implementation (#611)
* Fixed PowerDNS plugin when using limited API key that doesn't have access to all hosted zones (#617) (Thanks @joachimcarrein)
* Removed the Warning message when creating a new ACME account with no `-Contact` parameter.

## 4.28.0 (2025-02-08)

* New [efficient iP SOLIDserver DDI](https://efficientip.com/products/solidserver-ddi/) plugin. Thanks @jamiekowalczik for the initial PR and @alexissavin for providing a test platform and API guidance.
* Experimental support for the new [ACME Profiles](https://datatracker.ietf.org/doc/draft-aaron-acme-profiles/) extension. This is still a very early draft standard and subject to change, but Let's Encrypt is already rolling out support this year as part of their short-lived certificates initiative. More info [here](https://letsencrypt.org/2025/01/09/acme-profiles/).
* Fixed Route53 plugin when used with accounts that have many hosted zones. (#593)
* Fixed a bug with DeSEC plugin that was caused by the previous fix for #584. (#598)
* Added better debug logging for DeSEC plugin.
* Azure cert thumbprint auth now works on Linux for certs in the "CurrentUser" store. (Thanks @Eric2XU)
* Fixed a bug with Azure cert thumbprint auth on Windows that could throw errors when using certificates with non-exportable private keys.
* Added better debug logging for Azure plugin.
* AcmeException objects thrown by the module now include the lower level HTTP response exception as an InnerException.

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

## 4.26.0 (2024-11-01)

* New DNS plugin [AddrTools](https://challenges.addr.tools/) (#572)
* Porkbun plugin updated with new API endpoint. Vendor decommissioning old endpoint on 2024-12-01. Please upgrade before then. (#570)
* Porkbun plugin added retry mechanic to deal with rate limiting errors.
* Fixed ARI related date parsing bug when using PowerShell 7+. (#578)

## 4.25.1 (2024-09-02)

* Fix Azure IMDS auth for Arc-enabled servers

## 4.25.0 (2024-08-18)

* New DNS plugins
  * [TencentDNS](https://dnspod.com/) which is a new plugin for DNSPod that uses the Tencent Cloud API which will eventually be required when the old DNSPod API is terminated. (#553) (Thanks @xiaotiannet)
  * [OnlineNet](https://www.scaleway.com/en/domains-and-dns/) which is Scaleway's legacy DNS API managed through `console.online.net`. (#557)
* Gandi plugin now supports Personal Access Tokens (PAT) auth in addition to legacy API Keys (#554)
* NameCom plugin now has better error handling and debug logs. NameCom users with 2FA enabled should also review the user guide about a setting that could break API access. (#556)
* Minor logging fix for Active24 plugin.
* Fixed a bug with ARI implementation that would fail renewals when the ACME server believes the replaced cert had already been replaced. (#560)
* Fixed a bug with ARI implementation that would throw errors when the cert being replaced did not contain an AKI extention. (#561)

## 4.24.0 (2024-06-19)

* DomainOffensive plugin updated with new API root and documentation links. (Thanks @henrikalves)
* Added [ARI (ACME Renewal Information)](https://datatracker.ietf.org/doc/draft-ietf-acme-ari/) support based on draft 04. This should be considered experimental until the RFC is finalized.
  * `ARIId` and `Serial` fields have been added to the output of `Get-PACertificate`
  * `DisableARI` switch added to `Set-PAServer` which disables ARI support for the server even it would otherwise be supported. This will primarily be useful if the ARI draft changes enough to break the current support and CAs update their implementations before the module can be updated. It may also be useful for providers with existing ARI support from an older unsupported draft.
  * `ReplacesCert` parameter added to `New-PAOrder` which takes an ARIId string as returned by `Get-PACertificate`. This will be ignored if the current ACME server doesn't support ARI or support has been explicitly disabled via `Set-PAServer`.
  * Order refreshes now perform an ARI check if supported and not disabled. The `RenewAfter` field is updated if the response indicates it is necessary.
  * `Submit-Renewal` now triggers an order refresh if ARI is supported and not disabled.

## 4.23.1 (2024-05-23)

* Fix DNSimple plugin not properly ignoring 404 API errors on PowerShell 5.1 (#549)

## 4.23.0 (2024-05-04)

* Added support for DNSimple user tokens which should allow for certs with names that span domains in multiple accounts.
* Added warning in GoDaddy guide about newly imposed limits on API access. (Thanks @webprofusion-chrisc)
* Fixed DNSimple plugin not removing challenge records (#548).
* Fixed cascading errors on public functions when running with little or no existing config. (#544)
* Fixed OVH plugin on PowerShell 5.1 by removing an accidentally added ternary operator. (#545) (Thanks @joshooaj)

## 4.22.0 (2024-04-12)

* New DNS plugin [WebsupportSK](https://www.websupport.sk/?ref=NTIqFFo7Rg). This will be useful to Active24 users who have been migrated to the new provider.
* Added additional debug logging for Active24 plugin.

## 4.21.0 (2024-03-08)

* New DNS plugin [WEDOS](https://www.wedos.com/zone/)
* Fixed OVH bug that prevented record creation at a zone apex most common when using DNS Alias support. Also added doc warning about time skew and better debug logging. (#535)

## 4.20.0 (2023-12-12)

* New DNS plugin [PowerDNS](https://www.powerdns.com/powerdns-authoritative-server)
* Fixed duplicate identifiers in the `Domain` parameter causing errors with some ACME servers. Identifiers will now be deduplicated prior to being saved and sent to the ACME server. (#517)
* Added `WSHDelayAfterStart` param to the WebSelfHost plugin which adds a configurable delay between when the challenge listener starts up and when it asks the ACME server to validate the challenges. (#518)
* Orders where the MainDomain is longer than 64 characters will not include a CN value in the Subject field of the certificate request sent to the ACME server. CNs longer than 64 characters were already being rejected by some CAs like Let's Encrypt because the x509 spec doesn't allow for it. [More Info](https://community.letsencrypt.org/t/simplifying-issuance-for-very-long-domain-names/207924)

## 4.19.0 (2023-08-26)

* New DNS plugins
  * [HurricaneElectricDyn](https://dns.he.net/) This is an alternative to the existing `HurricaneElectric` plugin that uses the DynDNS API instead of web scraping. (Thanks @jbrunink)
  * [ZoneEdit](https://www.zoneedit.com/) (#495)
* The `CSRPath` parameter in `New-PAOrder` and `New-PACertificate` will now accept the raw string contents of a CSR file instead of just the path to a file. (#503)
* The `Simply` plugin has been renamed to `SimplyCom` at the request of the provider. The new version is exactly the same. The old version will remain until the next major release. Users should update their renewal configs to use the new version to prevent future breakage. `Set-PAOrder -Plugin SimplyCom`
* Added a workaround to a temporary problem with the Simply.com API in case the issue pops up again. (#502)
* The `Route53` plugin now uses IMDSv2 when using the IAM Role support. (#509)

## 4.18.0 (2023-06-28)

* The `POSHACME_HOME` environment variable now supports Windows-style (surrounded by `%`) environment variable expansion. (#497)
  * So you can set the value to `%ProgramData%\Posh-ACME` instead of needing to set it explicitly to `C:\ProgramData\Posh-ACME` for example.
  * NOTE: This requires Windows-style environment variable strings even on non-Windows OSes.
* The Azure plugin no longer tries to re-use cached authentication tokens when using the `AZAccessToken` parameter set. (#498)
* Fixed a bug with the Azure plugin that broke authentication when submitting multiple orders with different credentials from different tenants. (#498)
* Fixed a problem using Posh-ACME within AWS Lambda due to non-standard dotnet runtime assembly configs. (#418) (Thanks @garthmccormack)
  * This fix involved changing the `RevocationReasons` enum from a .NET type to a PowerShell native enum.
  * The change constitutes a minor breaking change which makes the enum no longer accessible from outside the module's context, but tab completion and string converted values for the `Revoke-PACertificate -Reason` parameter work exactly the same as before.

## 4.17.1 (2023-03-29)

* Fixed Hetzner plugin for accounts with 100+ zones. (#481) (Thanks @Deutschi)
* Fixed RFC2136 plugin ignoring the DDNSNameserver parameter when set. (#485) (Thanks @gvengel)

## 4.17.0 (2023-02-20)

* New DNS plugins
  * [Google Domains](https://domains.google/) This should be considered experimental while the Google Domains ACME API is still in testing. (Thanks @webprofusion-chrisc)
  * [IONOS](https://www.ionos.de/) (Thanks @RLcyberTech)
  * SSHProxy sends update requests via SSH to another server which is able to do dynamic updates against your chosen DNS provider. (Thanks @bretgiddings)
* The `DDNSNameserver` parameter is no longer mandatory in the RFC2136 plugin which will make nsupdate try to use whatever primary nameserver is returned from an SOA query.
* Added Basic authentication support to the AcmeDns plugin which should allow it to be used against endpoints that enforce that such as [Certify DNS](https://docs.certifytheweb.com/docs/dns/providers/certifydns/).
* Added support for plugin parameters that are arrays of SecureString or PSCredential objects.
* Fixed PAServer switches getting reset on `Set-PAServer` with no params (#475)

## 4.16.0 (2022-11-23)

* New DNS plugins
  * [Active24](https://www.active24.cz/) (Thanks @pastelka)
  * [Bunny.net](https://bunny.net/) (Thanks @webprofusion-chrisc)
* Added `-Subject` parameter to `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder` which will override the default x509 Subject field in the certificate request sent to the ACME CA. This can be useful for private CAs that allow for additional attributes in the Subject that public CAs don't.
* Fix for undocumented NameSilo API change. (Thanks @rkone)
* Fix for All-Inkl plugin that makes the plaintext `KasPwd` parameter actually send plaintext since All-Inkl has deprecated the SHA1 option.

## 4.15.1 (2022-09-09)

* Reverted the embedded BouncyCastle library back to 1.8.8 due to version conflicts with Az.KeyVault in PowerShell 6+. This is temporary while a suitable workaround for version conflicts in other modules is explored.
* Fixed Domeneshop plugin when publishing apex TXT records and added more API output to debug messages.

## 4.15.0 (2022-08-26)

* PAOrder objects now have a flag to optionally use modern encryption options on generated PFX files. This will prevent the need to use "legacy" mode when reading the files with OpenSSL 3.x. However, it breaks compatibility with OpenSSL 1.0.x and earlier.
  * You can use the `-UseModernPfxEncryption` flag with `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder`. When used with `Set-PAOrder`, existing PFX files will be re-written based on the flag's new value.
  * Use `Set-PAOrder -UseModernPfxEncryption:$false` to switch back to the default setting.
  * The default for new orders will likely remain off until Posh-ACME 5.x is released.
* Added new DNS plugin [PortsManagement](https://portsgroup.com/) (Thanks @wemmer)
* The GCloud plugin has a new optional parameter, `GCProjectId` that takes one or more string values. This is only required if the DNS zones to modify don't reside in the same project as the service account referenced by `GCKeyFile` or they reside in multiple projects. When used, be sure to include all project IDs including the one referenced by `GCKeyFile`.
* Added Google's new free ACME CA to the CA comparison doc
* Upgraded the embedded BouncyCastle library to 1.9.0
* Fixed UKFast plugin to support paging for accounts with many domains (Thanks @0x4c6565)
* Fixed PFX friendly name generation when not provided in the order.

## 4.14.0 (2022-04-12)

* Added new DNS plugin [Porkbun](https://porkbun.com/) (Thanks @CaiB)
* Added server shortcuts for Google's new ACME CA, GOOGLE_PROD and GOOGLE_STAGE.
* Added server shortcuts for SSL.com, SSLCOM_RSA and SSLCOM_ECC.
* Added `UseAltAccountRefresh` switch to `Set-PAServer` to workaround CAs that don't yet support direct account refreshes such as Google, SSL.com, and DigiCert. (#372) (#394)
  * New configs should have this set by default for CAs known to need it. But you will need to explicitly set it on any existing configs for these CAs.
* Added `LifetimeDays` param on `New-PACertificate`, `New-PAOrder`, and `Set-PAOrder` to enable user requested cert lifetimes for ACME CAs that support the feature.
  * Google's CA is the only free ACME CA known to currently support this and the order lifetime cannot be changed once it is created. Setting a new value on an existing order will only change the lifetime on subsequent renewals.
* Updated Azure plugin to use the latest stable API version.
* Updated Azure guide to account for breaking changes in the Az module.
* Fixed GoDaddy plugin when using it with delegated sub-zones. (#430)
* Fixed `New-PAAccount` when importing an existing key on CAs that require external account binding.
* Reduced the number of account refreshes that happen as part of normal operations.

## 4.13.1 (2022-03-14)

* Fixed Loopia plugin after an upstream API change broke it. (Thanks @AlexanderRydberg)

## 4.13.0 (2022-03-07)

* Added new DNS plugin [LeaseWeb](https://www.leaseweb.com/)
* Simply plugin migrated to v2 of the API. No changes should be necessary for existing users.

## 4.12.0 (2022-01-13)

* The WebRoot plugin now supports multiple paths for the `WRPath` parameter. (#411)
* ClouDNS plugin error handling was modified so that invalid credential errors are properly surfaced instead of just throwing generic "zone not found" errors. (#414)
* Fixed a potential bug with `Submit-OrderFinalize` when multiple orders have the same MainDomain property.
* Fixed `New-PACertificate` not properly updating an existing order with updated order params (#412)

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
* Fixed usage example in EasyDns guide. (Thanks @webprofusion-chrisc) (#407)

## 4.10.0 (2021-10-06)

* Added new DNS plugin [CoreNetworks](https://www.core-networks.de/) (Thanks @dwydler)
* Fix for Regru plugin bug caused by provider API change (#392)
* Fix Submit-Renewal duplicating orders that have a custom name (#393)

## 4.9.0 (2021-09-21)

* Added new DNS plugin [ISPConfig](https://www.ispconfig.org/)
* Fixed the DOCean plugin when used with accounts that have more than 20 zones. (#384) (Thanks @Xpyder)
* Fixed a bug in the DOCean plugin that prevented publishing records against the zone apex.
* Fixed a bug using `Set-PAOrder -PreferredChain` on an existing but expired order that was recently upgraded from Posh-ACME 3.x.
* Fixed renewal window calculation for certs that have lifetimes shorter or longer than 90 days. (#382) (Thanks @lookcloser)
  * Due to the bug, certs with lifetimes longer than 90 days would renew early and certs with lifetimes shorter than 90 days would renew late or potentially not at all. Because the renewal window is calculated and saved at finalization time, the new module version won't fix the value on existing orders. It will only fix future orders/renewals.
  * If you want to scan for and fix any orders that might have been affected by this bug, you can use the script posted here: https://github.com/rmbolger/Posh-ACME/issues/382#issuecomment-922128237
* Fixed a benign bug with object serialization in PS 5.1 that was saving the dynamic attributes on server/account/order objects.

## 4.8.1 (2021-09-12)

* Fixed a bug introduced in 4.7.0 that broke `Set-PAAccount -UseAltPluginEncryption` preventing plugin args for orders from being properly re-encrypted.

## 4.8.0 (2021-09-09)

* Documentation Revamp
  * https://poshac.me/docs is a new dedicated website for Posh-ACME documentation. Existing guides and tutorials have been migrated there from the Github wiki. The site is currently generated using the Markdown files in the `docs` folder in the main project repository by [MkDocs](https://www.mkdocs.org/). So it should now be easier to contribute fixes and updates.
  * The native module help is now also generated by [platyPS](https://github.com/PowerShell/platyPS) from the Markdown files in `docs/Functions`.
  * `Get-Help <function name> -Online` should now open your browser to the appropriate page on the documentation site.
* The DeSEC plugin has new `DSCToken` and `DSCTTL` params to avoid conflicts with the DNSimple plugin. The old `DSToken`, `DSTokenInsecure`, and `DSTTL` parameters have been deprecated.
* "Insecure" plugin parameter sets which include secrets, tokens, or passwords using a standard String instead of a SecureString or PSCredential have been deprecated across all plugins that had them.
  * Deprecated means that they will continue to work in Posh-ACME 4.x, but will stop working when 5.0 is released.
  * If you are currently using a deprecated parameter set, please migrate to a secure one when convenient.
  * See your plugin's [usage guide](https://poshac.me/docs/v4/Plugins/) for more information.
  * For help finding deprecated parameters in your config, see [this guide](https://poshac.me/docs/v4/Guides/Find-Deprecated-PluginArgs/)
* The following plugins have added new "Secure" parameter sets:
  * BlueCat
  * Cloudflare
  * DOcean
  * Dreamhost
  * Dynu
  * EasyDNS
  * GoDaddy
  * NameCom
  * Zonomi
* A `Plugin` property has been added to the output objects returned by `Get-PAPlugin <Plugin> -Params`

## 4.7.1 (2021-08-28)

* Fixed a parameter binding bug in New-PACertificate that could cause renewals to stall in some cases due to an interactive prompt.
* Fixed help for Export-PAAccountKey

## 4.7.0 (2021-08-24)

* Servers, Accounts, and Orders all now have configurable Names that also determine the name of their associated folders in the config on the filesystem. (#345) This is a fairly large change, but significant effort has been spent implementing it so that dependent scripts will not break.
  * **Please backup your current config before customizing your object names.** Previous Posh-ACME versions will break trying to read configs with custom names.
  * All customized names may only use the following characters to avoid cross-platform filesystem compatibility issues: `0-9 a-z A-Z - . _ !`.
  * A `NewName` parameter has been added to `Set-PAServer`, `Set-PAAccount`, and `Set-PAOrder` to change the name of each type of object.
  * Server related functions now have an optional `Name` parameter which can be used instead of or in addition to the `DirectoryUrl` parameter. This includes `Get/Remove/Set-PAServer`.
  * If a server doesn't already exist, `Set-PAServer` will use the `-Name` parameter for the new server's name. If the server already exists, it is ignored.
  * Returned server objects now have `Name` and `Folder` properties.
  * Despite being able to customize Server names, you may still only have a single instance of each unique ACME server in your config. This may chang in a future major version.
  * Account related functions that have an `ID` parameter now have a `Name` parameter alias. This includes `Get/Remove/Set-PAAccount` and `Export-PAAccountKey`. The ID parameter should be considered deprecated and in future major versions will be replaced by `Name`.
  * The `ID` parameter was added to `New-PAAccount` to allow setting the customized ID on creation instead of using the server provided default value.
  * Returned account objects now have a `Folder` property and the `id` property now reflects the customizable value.
  * The `id` property on account objects is deprecated and will be changed to `Name` in a future major version.
  * Order related functions now have an optional `Name` parameter to distinguish between multiple orders that may have the same `MainDomain`. This includes `Get/Revoke/New-PACertificate`, `Get/New/Set/Remove-PAOrder`, `Get-PAPluginArgs`, `Invoke-HttpChallengeListener`, and `Submit-Renewal`. In most cases, the `Name` parameter can also be used by itself as a unique identifier for orders.
  * The `Name` parameter on `New-PACertificate` and `New-PAOrder` allows setting the customized order name on creation instead of using the MainDomain default value.
  * Returned order objects now have a `Name` property (not to be confused with `FriendlyName` which only affects the certificate associated with the order).
  * Order related error and log messages that previously mentioned the order's MainDomain have been changed to use the order's Name instead.
  * To retain backwards compatibility with existing 4.x dependent scripts, `Get-PAOrder` will return the single, most recent order when used with `-MainDomain` even if there are multiple matching orders. This also affects `Get-PACertificate` which uses Get-PAOrder under the hood.
  * `Set-PAOrder`, `Revoke-PACertificate`, and `Remove-PAOrder` will throw an error if only `MainDomain` is specified and it matches multiple orders. Specify the `Name` parameter as well to ensure a unique order match.
* Custom plugins can now be loaded from an alternate filesystem location by creating a `POSHACME_PLUGINS` environment variable before the module is loaded. The value should be a folder path that contains uniquely named .ps1 plugin files. If any custom plugins have the same name as native plugins, a warning will be thrown and they will not be loaded.
* Added `New-PAAuthorization` which allows the creation of authorization objects outside the context of an order. NOTE: BuyPass is the only free ACME CA that currently supports this feature.
* Added a `OnlyReturnExisting` parameter to `New-PAAccount` when using an imported key which instructs the ACME server to only return account details if an account already exists for that key.
* Added a `NoSwitch` parameter to `Set-PAServer` so you can modify the active server without switching to it.
* The `AllSANs` field on PACertificate objects now reflects the SAN list on the actual certificate instead of its associated ACME order (just in case the two lists have divered for some strange reason).
* Added missing help on `Get-PAPluginArgs`.
* Default formatting for PAServer objects has been tweaked to show more useful info.
* Default formatting for PAOrder object now includes `Name` and has removed `OSCPMustStaple`.
* The `Quiet` parameter has been removed from the `Get-PAServer -List` parameter set because it didn't make sense.
* Fixed an example in `Remove-PAServer` help.
* Added workaround for BuyPass bug that prevents some error details from being parsed.
* Adjusted support for Account Key Rollover to more closely follow RFC8555 which fixes a bug using it with BuyPass
* Changed some logic in `Revoke-PACertificate` so that it works with BuyPass which doesn't seem to support revocation using the cert's private key.
* Orders using an ECC private key will no longer include Key Encipherment in the CSR's keyUsage when submitting an order for finalization. Key Encipherment is not supported for ECDSA certs and some CAs were rejecting the finalization.

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

## 4.5.0 (2021-05-29)

* Added new DNS plugins
  * Aurora for [PCExtreme](https://pcextreme.nl/) (Thanks @j81blog)
  * [UKFast](https://ukfast.co.uk/) (Thanks @Overglazed)
* Added new function `Revoke-PACertificate` which provides more options for cert revocation including the ability to revoke certs not created with other clients or ACME accounts if you have the private key.
* Added `ManualNonInteractive` switch to the Manual plugin to suppress the interactive prompt after showing the TXT record details that need to be created. (Thanks @hhhuut)
* Added additional guidance in the plugin dev guide.
* Optimized module load time by pre-caching native plugin details.
* Fixed support for IDN domains in Simply plugin (Thanks @Norskov)
* Fixed Azure plugin bug when DnsAlias matches the zone apex. (#348)
* Fixed Azure plugin to support IMDS auth within Azure Automation. (#349)
* Fixed tests for Pester 5.2

## 4.4.0 (2021-05-03)

* Added new DNS plugins
  * [Constellix](https://constellix.com/)
  * [All-Inkl](https://all-inkl.com/) (Thanks @astaerk)
  * [Easyname](https://www.easyname.com/) (Thanks @codemanat)
* Added `Folder` property to Get-PAOrder output
* Added `KeyFile` parameter to New-PAOrder to allow importing an existing private key

## 4.3.2 (2021-03-13)

* Fixed New-PACertificate not using the previous order's KeyLength value if it exists and wasn't overridden by an explicit parameter value. (#326)
* Fixed `Submit-Renewal` not sending all previous order parameters to `New-PACertificate` (#326) (Thanks @juliansiebert)
* Fixed module load errors for some environment with older .NET Framework versions.

## 4.3.1 (2021-03-12)

* Fixed Route53 plugin to check for pre-imported AWS module (#324)
* Fixed telemetry ping not respecting DisableTelemetry option in `Set-PAServer`
* Telemetry ping no longer uses `Start-Job` which should avoid errors when running in Azure functions and other scenarios where PowerShell is hosted within another application.

## 4.3.0 (2021-02-24)

* PreferredChain selection logic has been updated to consider "distance from root" as a way to break ties when the specified CA subject is found in multiple chains. Chains with the CA closer to the root take precedence over ones with it further away. (#315)
* `CFTokenReadAll` and `CFTokenReadAllInsecure` have been removed from the Cloudflare plugin because they are no longer needed. Cloudflare fixed the API bug that made them necessary when using edit tokens scoped to a specific zone or zones. No user action is required if you were previously using these parameters. They will simply be ignored.
* HTTP call detail has been changed from Verbose to Debug output in Cloudflare and Route53 plugins.
* Fixed CSR handing for CSRs that have no attributes (#317) (Thanks @methorpe)
* Fixed Route53 plugin compatibility with older versions of the AWSPowerShell module (#318)

### Deprecation Notice

Many plugins have optional parameter sets that use "Insecure" versions of the primary SecureString or PSCredential parameters due to bugs in early versions of PowerShell 6 that prevented using them on non-Windows OSes. Those bugs have been fixed since PowerShell 6.2 and the insecure parameter sets should be considered deprecated and will likely be removed in the next major version (5.x) of Posh-ACME. Individual plugin usage guides will slowly be updated over the course of 4.x to warn about the specific parameter deprecations.

## 4.2.0 (2021-02-01)

* Added new DNS plugins
  * Infomaniak (Thanks @Sundypha)
  * Zilore
* Added `ACMEUri` option to AcmeDns plugin which allows specifying the complete URI instead of just the hostname. (Thanks @AvrumFeldman)

## 4.1.0 (2021-01-18)

* Compatibility updates for RFC2136 plugin (#308)
  * Now uses exit code from nsupdate instead of output parsing to determine success and avoid possible language inconsistencies (#307)
  * Added optional DDNSZone param to avoid initial SOA lookup that breaks in some environments (#307)
* Removed UnoEuro plugin because API endpoint is no longer functional. Users should switch to the Simply plugin. (#303)
* Moved HTTP call detail from Verbose to Debug output for Infoblox plugin
* Fixed partial zone matching bug for Domeneshop plugin (#305)
* Fixed `Submit-Renewal -AllOrders` so it no longer skips invalid or pending orders

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


## 3.20.0 (2020-11-25)

* Azure plugin now supports other Azure cloud environments via the `AZEnvironment` parameter. Supported values are `AzureCloud` (Default), `AzureUSGovernment`, `AzureGermanCloud`, and `AzureChinaCloud`. (#293) (Thanks @InKahootz)
* Fixed parameter binding and other bugs in Simply plugin. (#294)

## 3.19.0 (2020-11-20)

* Added new DNS plugin [Simply](https://www.simply.com/) who recently changed their name from UnoEuro. Existing users of the UnoEuro plugin should migrate to the Simply plugin as soon as possible because the UnoEuro plugin may stop working if they decommission the old API endpoint.
* Warnings have been added to the UnoEuro plugin to inform users about migrating to Simply.
* Updated DNSPod plugin to work with their recent API changes. Existing users will need to generate a new API key from the management console and update the plugin args for their orders. See the [usage guide](https://github.com/rmbolger/Posh-ACME/blob/master/Posh-ACME/DnsPlugins/DNSPod-Readme.md) for details.
* Fixed a bug in `New-PAAccount` when the account location URI had query parameters. (Thanks @KaiWalter)

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
