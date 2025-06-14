title: Netcup

# How To Use the Netcup DNS Plugin

This plugin works against the [Netcup](https://www.netcup.com) domain registrar. It is assumed that you have already setup an account and registered the domains you will be working against. The domains must not be using custom DNS servers.

## Setup

Login to the Customer Control Panel and navigate to [Master Data - API](https://www.customercontrolpanel.de/daten_aendern.php?sprung=api).

In the `Creating an API Key` section, agree to the TOS and click `API key Create`. Record the new value that appears in the `API keys` section. This will be the username for the credential object we'll setup later. There can be many API keys associated with the account.

In the `API management` section, click `Generate API Password` and then click OK. Record the password value that is displayed. It cannot be retrieved later and it will be the password for the credential object we'll setup later. Generating a new API password immediately deactivates the previous one.

## Using the Plugin

The username that you use to login to the Control Panel is your customer number and is used with the `NetcupCustNumber` parameter. The API Key and Password you created earlier will be used as the Username and Password for a PSCredential parameter called `NetcupAPICredential`.

!!! warning
    DNS updates in Netcup take a long time to propagate to the authoritative nameservers relative to other providers. You will need to set the `-DnsSleep` parameter to at least 10 minutes, but potentially to 15-20 minutes to ensure the records are live before trying to validate the ACME challenges with Posh-ACME.


```powershell
$pArgs = @{
    NetcupCustNumber = 123456
    NetcupAPICredential = (Get-Credential)
}
New-PACertificate example.com -Plugin Netcup -PluginArgs $pArgs -DnsSleep 900
```
