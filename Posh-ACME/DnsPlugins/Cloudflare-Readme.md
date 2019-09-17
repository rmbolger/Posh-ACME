# How To Use the Cloudflare DNS Plugin

This plugin works against the [Cloudflare](https://www.cloudflare.com/dns) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

There are two choices for authentication against the Cloudflare API. The old way uses your account email address and a "Global API Key" that has complete access to your account. Cloudflare now also supports API Tokens that can be limited to only certain permissions within the account. This is the recommended method to use. Open the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page to get started.

### API Token

* In the API Tokens section, click `Create Token`
* Give it a name such as 'posh-acme'
* Add the following permissions:
  * Zone - Zone Settings - Read
  * Zone - Zone - Read
  * Zone - DNS - Edit
* Zone Resources can be configured for whatever set of zones you'll be using Posh-ACME with. But if you're unsure, just leave it as `Include - All zones` which is the default.
* Click `Continue to summary`
* Click `Create Token`
* Copy the token value for later. These values can't be retrieved later. You must generate a new value if you forget the old one.

### Global API Key

* In the API Keys section, click `View` for the "Global API Key"
* You may need to re-enter the account password and answer a CAPTCHA.
* Copy the key value for later.

## Using the Plugin

If you're using the newer API Token method, you'll use the previously retrieved token value with either `CFToken` or `CFTokenInsecure`. The former requires a SecureString value which can only be used on Windows OSes or any OS with PowerShell 6.2 or later. If you're using the Global API Key method, you'll need to use the `CFAuthEmail` and `CFAuthKey` parameters with the account's email address and previously retrieved Global API Key.

### API Token Secure (Windows or PS 6.2+)

```powershell
$secToken = Read-Host -AsSecureString -Prompt 'API Token'
$pArgs = @{ CFToken = $secToken }
New-PACertificate example.com -DnsPlugin Cloudflare -PluginArgs $pArgs
```

### API Token Insecure (Any OS)

```powershell
$pArgs = @{ CFTokenInsecure = 'xxxxxxxxxx' }
New-PACertificate example.com -DnsPlugin Cloudflare -PluginArgs $pArgs
```

### Global API Key (Any OS)

```powershell
$pArgs = @{ CFAuthEmail='xxxx@example.com'; CFAuthKey='xxxxxxxx' }
New-PACertificate example.com -DnsPlugin Cloudflare -PluginArgs $pArgs
```
