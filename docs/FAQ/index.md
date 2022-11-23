---
title: FAQ
hide:
  - navigation
---

# Frequently Asked Questions (FAQ)

## Where is my config? Where is my cert?

Unless you have [changed the default](../Guides/Using-an-Alternate-Config-Location.md), all Posh-ACME config is in your user profile depending on the OS:

- Windows: `%LOCALAPPDATA%\Posh-ACME`
- Linux: `$HOME/.config/Posh-ACME`
- MacOS: `$HOME/Library/Preferences/Posh-ACME`

The full paths to all cert files for the current order is in the detailed output of `Get-PACertificate`.

```powershell
Get-PACertificate | Format-List
```

## How Do I Upgrade From 3.x to 4.x?

If your certificate renewals are using `Submit-Renewal`, no changes should be necessary in order to upgrade from 3.x to 4.0 unless you were using the `-NewKey` parameter which has been removed. Orders can now be configured to always generate a new private key using `Set-PAOrder -AlwaysNewKey`. For example, you can set the flag for all orders in an account like this:

```powershell
Get-PAOrder -List | Set-PAOrder -AlwaysNewKey
```

For custom scripts that use more of the module's functions be aware of the following changes:

* `Invoke-HttpChallengeListener` is deprecated and may be removed in a future release. Users should migrate to the `WebSelfHost` plugin.
* `Publish/Unpublish/Save-DnsChallenge` functions have been renamed to `Publish/Unpublish/Save-Challenge`.
* All references to the `DnsPlugin` parameter should be replaced with `Plugin`.
* `NewKey` has been removed from `Submit-Renewal`.
* `NewKey`/`NewCertKey` have been replaced by `AlwaysNewKey` in `New-PACertificate` and `New-PAOrder`.
* `AlwaysNewKey` has been added to `Set-PAOrder`.
* `DnsPlugin`, `PluginArgs`, `DnsAlias`, `DnsSleep`, `ValidationTimeout` and `Account` parameters have been removed from `Submit-ChallengeValidation`. The account associated with the order must be the currently active account. The rest of the parameters are read directly from the order object and can be modified in advance with `Set-PAOrder` if necessary.
* The `NoPrefix` switch in `Publish/Unpublish-Challenge` has been replaced with a `DnsAlias` parameter that will override the `Domain` parameter if specified. "_acme-challenge." will not be automatically added to `DnsAlias` values. For example:

```powershell
# Old 3.x method to publish an alias
Publish-DnsChallenge -Domain alias.example.com -NoPrefix -DnsPlugin MyPlugin -Account (Get-PAAccount) -Token xxxx -PluginArgs $pArgs

# New 4.x method to publish an alias
Publish-DnsChallenge -Domain example.com -DnsAlias alias.example.com -Plugin MyPlugin -Account (Get-PAAccount) -Token xxxx -PluginArgs $pArgs
```

If your workflow relied on new orders automatically using the plugin args from previously configured orders, that no longer works and you will have to explicitly set the `-PluginArgs` parameter for each new order. However, you can use `Get-PAPluginArgs` to make it easier. For example:

```powershell
# Old 3.x method where new order uses old plugin args automatically
New-PACertificate www1.example.com -Plugin MyPlugin -PluginArgs @{MyArg='xxxx'}
New-PACertificate www2.example.com -Plugin MyPlugin

# New 4.x method
New-PACertificate www1.example.com -Plugin MyPlugin -PluginArgs @{MyArg='xxxx'}
$pArgs = Get-PAPluginArgs www1.example.com
New-PACertificate www2.example.com -Plugin MyPlugin -PluginArgs $pArgs
```

## How have Plugins changed in 4.x?

See the [Migrating DNS Plugins from 3x to 4x](../Plugins/Plugin-Development-Guide.md#migrating-dns-plugins-from-3x-to-4x) section of the plugin development guide.

## Does Posh-ACME work cross platform on PowerShell Core?

Yes as of 2.2.0!...with a few caveats.

The `-Install` parameter in `New-PACertificate` is not supported on non-Windows platforms and will throw an error if used because there's no certificate store equivalent to install to.

On non-Windows OSes, `[securestring]` and `[pscredential]` plugins are not encrypted on disk by default because the encryption APIs used on Windows aren't available. However, you can enable AES based encryption that is also portable between OSes on a per-account level. This can be done during account creation or after the fact and you can switch between native and AES encryption at any time as in the following examples:

```powershell
# enable AES encryption during account creation
New-PAAccount -AcceptTOS -Contact me@example.com -UseAltPluginEncryption

# enable AES encryption on an existing account
Set-PAAccount -UseAltPluginEncryption

# switch back to OS-native encryption on an existing account
Set-PAAccount -UseAltPluginEncryption:$false
```

## Key not valid for use in specified state

This can happen on Windows if you try to copy the Posh-ACME profile folder to a different Windows computer or a different user's profile on the same computer. The underlying APIs used to encrypt plugin parameters using `SecureString` and `PSCredential` objects are tied to both the current computer and user and are not portable. However, you can use the `Set-PAAccount -UseAltPluginEncryption` to change the encryption used for the account to a portable AES based method and then copy the profile.


## The underlying connection was closed: Cloud not establish trust relationship for the SSL/TLS secure channel.

This shouldn't ever happen when using a publicly trusted certificate authority such as Let's Encrypt. If it does, an attacker or malware might be trying to [MitM](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) your connection.

However if you're doing development against a test ACME server like [Pebble](https://github.com/letsencrypt/pebble) or a private instance of [Boulder](https://github.com/letsencrypt/boulder), this is normal because the server is likely using a self-signed certificate. You can work around the problem by adding the `-SkipCertificateCheck` parameter to `Set-PAServer`.

If the error seems to originate from one of the plugins, submit an [issue](https://github.com/rmbolger/Posh-ACME/issues) and we can figure it out.

## Access is denied

The most common reason this error shows up is that you used the `-Install` parameter with `New-PACertificate` and you're not running PowerShell as an elevated process (Run as Administrator). Both the original call to `New-PACertificate` and any subsequent calls to `Submit-Renewal` need to run elevated for the module to install the resulting certificate.

## Refer to sub-problems for more information.

This is generally part of a longer error message and most often shows up when you're trying to create a certificate with multiple names. It means that the error body has additional detail that can help identify what went wrong. You can access the sub-problem data from the Exception object like this.

```powershell
# If you haven't caught the error in a try/catch block, it should be in the first index in the error object
$Error[0].Exception.Data.subproblems | Format-List

# If you did catch the error, it will be in the $_ object
catch {
    $_.Exception.Data.subproblems | Format-List
}
```
