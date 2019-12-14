# Posh-ACME

An [ACME v2 (RFC 8555)](https://tools.ietf.org/html/rfc8555) client implemented as a Windows PowerShell module that enables you to generate publicly trusted SSL/TLS certificates from an ACME capable certificate authority such as [Let's Encrypt](https://letsencrypt.org/).

# Notable Features

- ACME v2 protocol support which allows generating wildcard certificates (*.example.com)
- Single command for new certs, `New-PACertificate`
- Easy renewals via `Submit-Renewal`
- RSA and ECC private keys supported for accounts and certificates
- Support for using existing certificate request (CSR)
- Account key rollover support
- [OCSP Must-Staple](https://scotthelme.co.uk/ocsp-must-staple/) support
- DNS challenge plugins for [various DNS providers](https://github.com/rmbolger/Posh-ACME/wiki/List-of-Supported-DNS-Providers) (pull requests welcome)
- DNS challenge [CNAME support](https://github.com/rmbolger/Posh-ACME/blob/master/Tutorial.md#advanced-dns-challenge-aliases)
- Help system for DNS plugins using `Get-DnsPlugins` and `Get-DnsPluginHelp`
- DNS plugins support batch updates
- Multiple accounts supported per user profile which allows different certs to have different contact emails
- PEM and PFX output files
- No elevated Windows privileges required *(unless using -Install switch)*
- Cross platform PowerShell Core support! [(FAQ)](https://github.com/rmbolger/Posh-ACME/wiki/Frequently-Asked-Questions-(FAQ)#does-posh-acme-work-cross-platform-on-powershell-core)
- Manual HTTP challenge support ([Guide](https://github.com/rmbolger/Posh-ACME/wiki/%28Advanced%29-Manual-HTTP-Challenge-Validation))

# Install

## Release

The [latest release version](https://www.powershellgallery.com/packages/Posh-ACME/) can found in the PowerShell Gallery. Installing from the gallery requires the PowerShellGet module which is installed by default on Windows 10 or later and all versions of PowerShell Core. See [Getting Started with the Gallery](https://www.powershellgallery.com/) for instructions on earlier OSes. Zip/Tar versions can also be downloaded from the [GitHub releases page](https://github.com/rmbolger/Posh-ACME/releases).

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-ACME

# install for current user
Install-Module -Name Posh-ACME -Scope CurrentUser
```

## Development

To install the latest *development* version from the git master branch, use the following PowerShell command. This method assumes a default PowerShell environment that includes the [`PSModulePath`](https://msdn.microsoft.com/en-us/library/dd878326.aspx) environment variable. You must also make sure `Get-ExecutionPolicy` does not return `Restricted` or `AllSigned`.

```powershell
# If necessary, set less restrictive execution policy.
# Not needed on non-Windows
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# install latest dev version
iex (irm https://raw.githubusercontent.com/rmbolger/Posh-ACME/master/instdev.ps1)
```

# Quick Start

If you're starting from a fresh install, the minimum parameters you need are the domain name for your cert and the `-AcceptTOS` flag.

```powershell
New-PACertificate site1.example.com -AcceptTOS
```

This uses the default `Manual` DNS plugin which requires you to manually edit your DNS server to create the TXT records required for challenge validation. Here's a more complete example with a typical wildcard cert utilizing a hypothetical `Flurbog` DNS plugin that also adds a contact email address to the account for expiration notifications.

```powershell
New-PACertificate '*.example.com','example.com' -AcceptTOS -Contact admin@example.com -DnsPlugin Flurbog `
                  -PluginArgs @{FBServer='fb.example.com'; FBCred=(Get-Credential)}
```

To learn how to use the supported DNS plugins, check out `Get-DnsPlugins` and `Get-DnsPluginHelp`. There's also a [tutorial](/Tutorial.md) for a more in-depth guide to using the module.

The output of `New-PACertificate` is an object that contains various properties about the certificate you generated. Only a subset of the properties are displayed by default. To see the full list including the filesystem paths to any certificate files that were generated, pipe the original output to `Format-List` or use `Get-PACertificate | Format-List`. The root config folder for all data saved by the module is either `%LOCALAPPDATA%\Posh-ACME` on Windows, `~/.config/Posh-ACME` on Linux, or `~/Library/Preferences/Posh-ACME` on Mac OS.


# Requirements and Platform Support

* Supports Windows PowerShell 5.1 or later (Desktop edition) **with .NET Framework 4.7.1** or later
* Supports [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/whats-new/what-s-new-in-powershell-core-60) 6.0 or later (Core edition) on all supported OS platforms.

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)
