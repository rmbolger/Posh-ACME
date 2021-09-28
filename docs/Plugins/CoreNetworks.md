title: CoreNetworks

# How To Use the Core Networks DNS Plugin

This plugin works against the [Core Networks](https://www.core-networks.de/) DNS provider. It is assumed that you have already setup an (API)Account and created the DNS zone(s) you will be working against.

## Setup

On your account [profile page](https://iface.core-networks.de/general/api/accounts), click `Add Access`. Give it custom a username and a strong password. Record the value to use later. You won't be able to go back and look it up after leaving the page.

At the moment, no Internationalized Domain Name (IDN) are supported.

## Using the Plugin

Your username and password are used with the `CoreNetworksCred` PSCredential parameter. There is also an optional `CoreNetworksApiRoot` parameter that currently defaults to `https://beta.api.core-networks.de`. Unless Core Networks changes that URL when the API is out of beta, you won't need to worry about it.

```powershell
$pArgs = @{
    CoreNetworksCred = (Get-Credential)
}
New-PACertificate example.com -Plugin CoreNetworks -PluginArgs $pArgs
```
