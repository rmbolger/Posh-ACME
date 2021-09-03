title: Cloudflare

# How To Use the Cloudflare DNS Plugin

This plugin works against the [Cloudflare](https://www.cloudflare.com/dns) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

There are two choices for authentication against the Cloudflare API. The old way uses your account email address and a "Global API Key" that has complete access to your account. Cloudflare also supports API Tokens that can be limited to only certain permissions within the account. This is the recommended method to use. Open the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page to get started.

### API Token

The API token will need `Zone - DNS - Edit` permissions on the zone(s) you will be requesting a certificate for. Many find it easiest to use `All zones` or `All zones from an account` in the Zone Resources section. But you may also limit the token to a subset of the account's zones using one or more instances of `Specific zone`.

* Click `Create Token`
* Find the `Edit zone DNS` token template and click `Use template`
* (Optional) Click the pencil icon to rename the token
* The Permissions list should already contain **Zone - DNS - Edit**
* Set Zone Resources to **Include - All zones** (or whatever alternative scope you like)
* (Optional) Add IP address filtering to limit where API requests can come from for this token
* (Optional) Set a TTL Start/End date. **NOTE: Setting a TTL will require generating a new token when it expires and updating your Posh-ACME config with the new value.**
* Click `Continue to summary`
* Click `Create Token`
* Copy the token value from the summary screen  because it can't be retrieved after leaving this page. You must generate a new value if you forget or lose the old one.

### Global API Key

* In the API Keys section, click `View` for the "Global API Key"
* You may need to re-enter the account password and answer a CAPTCHA.
* Copy the key value for later.

## Using the Plugin

If you're using the newer API Token method, you'll use it with the `CFToken` SecureString parameter. If you're using the Global API Key method, you'll need to use the `CFAuthEmail` and `CFAuthKeySecure` parameters with the account's email address as a string and previously retrieved Global API Key as a SecureString.

*NOTE: The `CFTokenInsecure` and `CFAuthKey` parameters are deprecated and will be removed in the next major module version. Please migrate to one of the Secure parameter sets.*

### API Token

```powershell
$secToken = Read-Host -AsSecureString -Prompt 'API Token'
$pArgs = @{ CFToken = $secToken }
New-PACertificate example.com -Plugin Cloudflare -PluginArgs $pArgs
```

### Global API Key

```powershell
$secKey = Read-Host -AsSecureString -Prompt 'Global API Key'
$pArgs = @{ CFAuthEmail='xxxx@example.com'; CFAuthKeySecure=$secKey }
New-PACertificate example.com -Plugin Cloudflare -PluginArgs $pArgs
```
