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
