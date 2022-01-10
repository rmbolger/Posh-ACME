# Posh-ACME

A [PowerShell](#requirements-and-platform-support) module and [ACME](https://tools.ietf.org/html/rfc8555) client to create publicly trusted SSL/TLS certificates from an ACME capable certificate authority such as [Let's Encrypt](https://letsencrypt.org/).

## Notable Features

- Multi-domain (SAN) and wildcard (*.example.com) certificates supported
- IP Address certificates ([RFC 8738](https://tools.ietf.org/html/rfc8738)) *(Requires ACME CA support)*
- All-in-one command for new certs, `New-PACertificate`
- Easy renewals with `Submit-Renewal`
- RSA and ECDSA keys supported for accounts and certificates
- Built-in validation plugins for [DNS and HTTP](https://poshac.me/docs/latest/Plugins/) based challenges. (pull requests welcome)
- Support for pre-created certificate requests (CSR)
- PEM and PFX output files
- No elevated Windows privileges required *(unless using `-Install` switch)*
- Cross platform PowerShell support. [(FAQ)](https://poshac.me/docs/latest/FAQ/#does-posh-acme-work-cross-platform-on-powershell-core)
- Account key rollover support
- [OCSP Must-Staple](https://scotthelme.co.uk/ocsp-must-staple/) support
- DNS challenge [CNAME support](https://poshac.me/docs/latest/Guides/Using-DNS-Challenge-Aliases/)
- Multiple ACME accounts supported per ACME CA.
- External Account Binding support for ACME CAs that require it [(Guide)](https://poshac.me/docs/Guides/External-Account-Binding/)
- Preferred Chain support to use alternative CA trust chains [(Guide)](https://poshac.me/docs/Guides/Using-Alternate-Trust-Chains/)
- PowerShell [SecretManagement](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/) support [(Guide)](https://poshac.me/docs/v4/Guides/Using-SecretManagement/)


## Installation (Stable)

The latest release can found in the [PowerShell Gallery](https://www.powershellgallery.com/packages/Posh-ACME/) or the [GitHub releases page](https://github.com/rmbolger/Posh-ACME/releases). Installing is easiest from the gallery using `Install-Module`. *See [Installing PowerShellGet](https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget) if you run into problems with it.*

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-ACME -Scope AllUsers

# install for current user
Install-Module -Name Posh-ACME -Scope CurrentUser
```

*NOTE: If you use PowerShell 5.1 or earlier, `Install-Module` may throw an error depending on your Windows and .NET version due to a change PowerShell Gallery made to their TLS settings. For more info and a workaround, see the [official blog post](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/).*

## Installation (Development)

[![Pester Tests badge](https://github.com/rmbolger/Posh-ACME/workflows/Pester%20Tests/badge.svg)](https://github.com/rmbolger/Posh-ACME/actions)

Use the following PowerShell command to install the latest *development* version from the git `main` branch. This method assumes a default [`PSModulePath`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath) environment variable and installs to the CurrentUser scope.

```powershell
iex (irm https://raw.githubusercontent.com/rmbolger/Posh-ACME/main/instdev.ps1)
```

You can also download the source manually from GitHub and extract the `Posh-ACME` folder to your desired module location.

## Quick Start

The minimum parameters you need for a cert are the domain name and the `-AcceptTOS` flag. This uses the default `Manual` DNS plugin which requires you to manually edit your DNS server to create the TXT records required for challenge validation.

```powershell
New-PACertificate example.com -AcceptTOS
```

NOTE: On Windows, you may need to set a less restrictive PowerShell execution policy before you can import the module.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Import-Module Posh-ACME
```

 Here's a more complete example with a typical wildcard cert utilizing a hypothetical `FakeDNS` DNS plugin that also adds a contact email address to the account for expiration notifications.

```powershell
$certNames = '*.example.com','example.com'
$email = 'admin@example.com'
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
New-PACertificate $certNames -AcceptTOS -Contact $email -Plugin FakeDNS -PluginArgs $pArgs
```

To learn how to use a specific plugins, check out `Get-PAPlugin <PluginName> -Guide`. There's also a [tutorial](Tutorial) for a more in-depth guide to using the module.

The output of `New-PACertificate` is an object that contains various properties about the certificate you generated. Only a subset of the properties are displayed by default. To see the full list including the filesystem paths to any certificate files that were generated, pipe the original output to `Format-List` or use `Get-PACertificate | Format-List`. You can also get the path to the server's config using `(Get-PAServer).Folder`.


## Requirements and Platform Support

* Supports Windows PowerShell 5.1 (Desktop edition) **with .NET Framework 4.7.1** or later
* Supports PowerShell 6.2 or later ([Core edition](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/differences-from-windows-powershell)) on all supported OS platforms.
* Requires `FullLanguage` [language mode](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes)

*NOTE: PowerShell 6.0-6.1 should also work, but there are known issues when using `SecureString` or `PSCredential` plugin args on non-Windows platforms.*

## Changelog

See [CHANGELOG.md](/CHANGELOG.md)
