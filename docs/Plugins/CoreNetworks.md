title: Core Networks GmbH

# How To Use the Core Networks DNS Plugin

This plugin works against the [Core Networks](https://www.core-networks.de/) DNS provider. It is assumed that you have already setup an (API)Account and created the DNS zone(s) you will be working against.

## Setup

On your account [profile page](https://iface.core-networks.de/general/api/accounts), click `Add Access`. Give it custom a username and a strong password. Record the value to use later. You won't be able to go back and look it up after leaving the page.

At the moment no Internationalized Domain Name (IDN) are supportet.

## Using the Plugin

The primary parameter you need with this plugin is `CoreNetworksApiRoot ` which is the root URL for the HTTP API such as `https://beta.api.core-networks.de`.
You'll also need to specify credentials as a PSCredential object with `CoreNetworksCred`.

```powershell
$pArgs = @{
    CoreNetworksApiRoot = 'https://beta.api.core-networks.de'
    CoreNetworksCred = (Get-Credential)
}
New-PACertificate -Domain "example.com" -Plugin CoreNetworks -PluginArgs $pArgs
