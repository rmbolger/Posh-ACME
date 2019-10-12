# How To Use the Unoeuro DNS Plugin

This plugin works against the [Unoeuro](https://www.unoeuro.com/dns) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Finding your information in Unoeuro

Using Unoeuro API requires only your account name or account number and API Key which can be found on the [account](https://www.unoeuro.com/en/controlpanel/account/) page.


## Using the Plugin

```powershell
$pArgs = @{ UEAccount='UE123456'; UEAPIKey='ABCDEFghijkLmNoPq' }
New-PACertificate example.com -DnsPlugin unoeuro -PluginArgs $pArgs
```