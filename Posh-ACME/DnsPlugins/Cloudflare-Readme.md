# How To Use the Cloudflare DNS Plugin

This plugin works against the Cloudflare provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against. 

## Setup

We need to retrieve the api keys of the account that will be used to update DNS records.  Login in to cloudflare, https://www.cloudflare.com/a/login using the account that will be used to update DNS.  Go to account settings, Account - API Keys section and retrieve the Global API Key.


## Using the Plugin

You will need the email address and associated Global API key of a cloudflare account that is a DNS administrator.

```powershell
$CFParams = @{CFAuthEmail='xxxxxxxx'; CFAuthKey='xxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin Cloudflare -PluginArgs $CFParams
```
