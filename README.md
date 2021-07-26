# Posh-ACME

An [ACME (RFC 8555)](https://tools.ietf.org/html/rfc8555) client implemented as a [PowerShell module](#requirements-and-platform-support) that enables you to generate publicly trusted SSL/TLS certificates from an ACME capable certificate authority such as [Let's Encrypt](https://letsencrypt.org/).

# Notable Features

- Multi-domain (SAN) and wildcard (*.example.com) certificates supported.
- [RFC 8738](https://tools.ietf.org/html/rfc8738) support for generating certificates for IP addresses (if your ACME CA supports it).
- Single command for new certs, `New-PACertificate`
- Easy renewals via `Submit-Renewal`
- RSA and ECC private keys supported for accounts and certificates
- Built-in validation plugins for [DNS](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) and [HTTP](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-HTTP-Plugins) based challenges. (pull requests welcome)
- Support for using existing certificate request (CSR)
- PEM and PFX output files
- No elevated Windows privileges required *(unless using -Install switch)*
- Cross platform PowerShell support. [(FAQ)](https://github.com/rmbolger/Posh-ACME/wiki/Frequently-Asked-Questions-(FAQ)#does-posh-acme-work-cross-platform-on-powershell-core)
- Account key rollover support
- [OCSP Must-Staple](https://scotthelme.co.uk/ocsp-must-staple/) support
- DNS challenge [CNAME support](https://github.com/rmbolger/Posh-ACME/blob/main/Tutorial.md#advanced-dns-challenge-aliases)
- Multiple accounts supported per certificate authority which allows different certs to have different contact emails
- Help system for DNS plugins using `Get-PAPlugin`
- External Account Binding support for CAs that require it
- Preferred Chain support to use alternative CA trust chains

# Install

## Release

The latest release version can found in the [PowerShell Gallery](https://www.powershellgallery.com/packages/Posh-ACME/) or the [GitHub releases page](https://github.com/rmbolger/Posh-ACME/releases). Installing from the gallery is easiest using `Install-Module` from the PowerShellGet module. See [Installing PowerShellGet](https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget) if you don't already have it installed.

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-ACME -Scope AllUsers

# install for current user
Install-Module -Name Posh-ACME -Scope CurrentUser
```

*NOTE: If you use PowerShell 5.1 or earlier, `Install-Module` may throw an error depending on your Windows and .NET version due to a change PowerShell Gallery made to their TLS settings. For more info and a workaround, see the [official blog post](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/).*

## Development

[![Pester Tests badge](https://github.com/rmbolger/Posh-ACME/workflows/Pester%20Tests/badge.svg)](https://github.com/rmbolger/Posh-ACME/actions)

To install the latest *development* version from the git main branch, use the following PowerShell command. This method assumes a default [`PSModulePath`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath) environment variable.

```powershell
# install latest dev version
iex (irm https://raw.githubusercontent.com/rmbolger/Posh-ACME/main/instdev.ps1)
```

# Quick Start

On Windows, you may need to set a less restrictive PowerShell execution policy before you can import the module.

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Import-Module Posh-ACME
```

The minimum parameters you need for a cert are the domain name and the `-AcceptTOS` flag.

```powershell
New-PACertificate example.com -AcceptTOS
```

This uses the default `Manual` DNS plugin which requires you to manually edit your DNS server to create the TXT records required for challenge validation. Here's a more complete example with a typical wildcard cert utilizing a hypothetical `Flurbog` DNS plugin that also adds a contact email address to the account for expiration notifications.

```powershell
$certNames = '*.example.com','example.com'
$email = 'admin@example.com'
$pArgs = @{FBCred=(Get-Credential)}

New-PACertificate $certNames -AcceptTOS -Contact $email -Plugin Flurbog -PluginArgs $pArgs
```

To learn how to use the supported DNS plugins, check out `Get-PAPlugin <PluginName> -Guide`. There's also a [tutorial](/Tutorial.md) for a more in-depth guide to using the module.

The output of `New-PACertificate` is an object that contains various properties about the certificate you generated. Only a subset of the properties are displayed by default. To see the full list including the filesystem paths to any certificate files that were generated, pipe the original output to `Format-List` or use `Get-PACertificate | Format-List`. The root config folder for all data saved by the module is either `%LOCALAPPDATA%\Posh-ACME` on Windows, `~/.config/Posh-ACME` on Linux, or `~/Library/Preferences/Posh-ACME` on Mac OS.


# Requirements and Platform Support

* Supports Windows PowerShell 5.1 (Desktop edition) **with .NET Framework 4.7.1** or later
* Supports [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-core-60) 6.2 or later (Core edition) on all supported OS platforms. *NOTE: 6.0-6.1 will also work, but there are known issues when using SecureString or PSCredential plugin args on non-Windows platforms.*
* Requires `FullLanguage` [language mode](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes)

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)
