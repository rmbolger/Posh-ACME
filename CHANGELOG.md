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
