# Posh-ACME

An [ACME v2](https://tools.ietf.org/html/draft-ietf-acme-acme) client implemented as a Windows PowerShell module that enables you to generate publicly trusted SSL/TLS certificates from an ACME capable certificate authority such as [Let's Encrypt](https://letsencrypt.org/).

# Notable Features

- ACME v2 protocol support which allows generating wildcard certificates (*.example.com)
- Single command for new certs, `New-PACertificate`
- Easy renewals via `Submit-Renewal`
- RSA and ECC private keys supported for accounts and certificates
- DNS challenge plugins for various DNS servers and providers (PRs welcome)
- DNS challenge CNAME support
- Help system for DNS plugins using `Get-DnsPlugins` and `Get-DnsPluginHelp`
- DNS plugins support batch updates
- Multiple accounts supported per user profile which allows different certs to have different contact emails
- PEM and PFX output files
- No elevated Windows privileges required

# Not Currently Supported (Yet)

- HTTP challenge support
- Pre/Post hooks to aid with certificate deployment and automation
- Account key rollover
- PowerShell Core support


# Install

The [latest release version](https://www.powershellgallery.com/packages/Posh-ACME) can found in the PowerShell Gallery. Installing from the gallery requires the PowerShellGet module which is installed by default on Windows 10 or later. See [Getting Started with the Gallery](https://www.powershellgallery.com/) for instructions on earlier OSes. Zip/Tar versions can also be downloaded from the [GitHub releases page](https://github.com/rmbolger/Posh-ACME/releases).

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-ACME

# install for current user
Install-Module -Name Posh-ACME -Scope CurrentUser
```

To install the latest *development* version from the git master branch, use the following command in PowerShell v3 or later. This method assumes a default Windows PowerShell environment that includes the [`PSModulePath`](https://msdn.microsoft.com/en-us/library/dd878326.aspx) environment variable which contains a reference to `$HOME\Documents\WindowsPowerShell\Modules`. You must also make sure `Get-ExecutionPolicy` is not set to `Restricted` or `AllSigned`.

```powershell
# (optional) set less restrictive execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# install latest dev version
iex (invoke-restmethod https://raw.githubusercontent.com/rmbolger/Posh-ACME/master/instdev.ps1)
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


# Requirements and Platform Support

* Requires Windows PowerShell 5.1 or later (a.k.a. Desktop edition).
* Requires .NET Framework 4.7.1 or later

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)
