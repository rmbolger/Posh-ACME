# How To Use the Cloudflare DNS Plugin

This plugin works against the [Cloudflare](https://www.cloudflare.com/dns) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

There are two choices for authentication against the Cloudflare API. The old way uses your account email address and a "Global API Key" that has complete access to your account. Cloudflare now also supports API Tokens that can be limited to only certain permissions within the account. This is the recommended method to use. Open the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page to get started.

### API Token

Cloudflare allows you to associate a token with all zones on the account or one specific zone. If you want to restrict `DNS - Edit` permissions to a single zone, you'll need to create a primary token with those permissions and a secondary token that has `Zone - Read` permissions to all zones in order for the plugin to successfully find the zone ID. Alternatively, you can create a single token that has both permissions on all zones.

**Primary/Secondary Example**

* In the API Tokens section, click `Create Token`
* Give it a name such as 'example.com edit'
* Add the following permission:
  * **Zone - DNS - Edit**
* Set the following Zone Resources:
  * **Include - Specific Zone - example.com**
* Click `Continue to summary`
* Click `Create Token`
* This is your primary token. Copy it for later because it can't be retrieved after leaving this page. You must generate a new value if you forget the old one.
* Click `View all API Tokens`
* In the API Tokens section, click `Create Token`
* Give it a name such as 'read all zones'
* Add the following permission:
  * **Zone - Zone - Read**
* Set the following Zone Resources:
  * **Include - All Zones**
* Click `Continue to summary`
* Click `Create Token`
* This is your secondary token. Copy it for later because it can't be retrieved after leaving this page. You must generate a new value if you forget the old one.

**Single Token Example**

* In the API Tokens section, click `Create Token`
* Give it a name such as 'DNS edit all zones'
* Add the following permissions:
  * **Zone - DNS - Edit**
  * **Zone - Zone - Read**
* Set the following Zone Resources:
  * **Include - All Zones**
* Click `Continue to summary`
* Click `Create Token`
* This is your token. Copy it for later because it can't be retrieved after leaving this page. You must generate a new value if you forget the old one.

### Global API Key

* In the API Keys section, click `View` for the "Global API Key"
* You may need to re-enter the account password and answer a CAPTCHA.
* Copy the key value for later.

## Using the Plugin

If you're using the newer API Token method, you'll use your primary token value with either `CFToken` or `CFTokenInsecure`. The former requires a SecureString value which can only be used on Windows OSes or any OS with PowerShell 6.2 or later. If you have a secondary token, you'll use it with either `CFTokenReadAll` or `CFTokenReadAllInsecure`, whichever version matches the primary token. If you're using the Global API Key method, you'll need to use the `CFAuthEmail` and `CFAuthKey` parameters with the account's email address and previously retrieved Global API Key.

### API Token Secure (Windows or PS 6.2+)

```powershell
$token = Read-Host -AsSecureString -Prompt 'API Token'
$pArgs = @{ CFToken = $token }
# (Optional) Only specify the ReadAll token if you generated one
$pArgs.CFTokenReadAll = Read-Host -AsSecureString -Prompt 'Secondary Token'
New-PACertificate example.com -DnsPlugin Cloudflare -PluginArgs $pArgs
```

### API Token Insecure (Any OS)

```powershell
$pArgs = @{ CFTokenInsecure = 'xxxxxxxxxx' }
# (Optional) Only specify the ReadAll token if you generated one
$pArgs.CFTokenReadAllInsecure = 'yyyyyyyyyy'
New-PACertificate example.com -DnsPlugin Cloudflare -PluginArgs $pArgs
```

### Global API Key (Any OS)

```powershell
$pArgs = @{ CFAuthEmail='xxxx@example.com'; CFAuthKey='xxxxxxxx' }
New-PACertificate example.com -DnsPlugin Cloudflare -PluginArgs $pArgs
```
