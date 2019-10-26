# How To Use the UnoEuro DNS Plugin

This plugin works against the [UnoEuro](https://www.unoeuro.com/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Finding your information in UnoEuro

Using UnoEuro API requires only your account name or account number and API Key which can be found on the [account](https://www.unoeuro.com/en/controlpanel/account/) page.


## Using the Plugin

```powershell
$pArgs = @{ UEAccount='xxxxxxxx'; UEAPIKey='yyyyyyyy' }
New-PACertificate example.com -DnsPlugin UnoEuro -PluginArgs $pArgs
```
