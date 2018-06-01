# How To Use the Linode DNS Plugin

This plugin works against the [Linode](https://www.linode.com/dns-manager) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

This plugin works against v4 of the Linode API which is not compatible with "legacy" pre-paid accounts. In order to use it and generate the appropriate API Token, your account must be a newer style "hourly billed" account which it should automatically be if you created it after late 2014.

Login to your account and go to the [API Tokens](https://cloud.linode.com/profile/tokens) section of your profile. Generate a Personal Access Token and give it Read/Write access to Domains. Record the value to use later. You can't retrieve it if you forget it. You can only delete and re-create.

## Using the Plugin

All you have to do is read in the token value as a secure string and then use it with the `LItoken` parameter. Linode also seems to have an unusually long DNS propagation delay. There's a note at the bottom of the DNS Manager web GUI that reads, "Changes made to a master zone will take effect in our nameservers every quarter hour." So you likely need to override the default `DnsSleep` parameter to 15 minutes (900 seconds) in order to ensure the TXT record changes have propagated.

```powershell
$token = Read-Host "Token" -AsSecureString
New-PACertificate test.example.com -DnsPlugin Linode -PluginArgs @{LIToken=$token} -DnsSleep 900
```
