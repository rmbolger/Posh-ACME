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
