# How To Use the Cloudflare DNS Plugin

This plugin works against the [Cloudflare](https://www.cloudflare.com/dns) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

We need to retrieve the Global API Key of the account that will be used to update DNS records. [Login](https://www.cloudflare.com/a/login) to Cloudflare using the account that will be used to update DNS. Go to the account's [Profile](https://dash.cloudflare.com/profile) page and click `View` on for the `Global API Key`. You'll have to re-enter the account password and answer a CAPTCHA.

## Using the Plugin

You will need the account's email address and previously retrieved Global API key to set as `CFAuthEmail` and `CFAuthKey`.

```powershell
$CFParams = @{CFAuthEmail='xxxxxxxx'; CFAuthKey='xxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin Cloudflare -PluginArgs $CFParams
```
