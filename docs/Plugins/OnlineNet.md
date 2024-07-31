title: OnlineNet

# How To Use the OnlineNet DNS Plugin

This plugin works against the [Online.net](https://www.scaleway.com/en/domains-and-dns/) DNS provider which is now known as Scaleway. However, this plugin only works against the legacy online.net v1 API. It is assumed that you have already setup an account and purchased the domain you will be working with that can be managed from the legacy [console.online.net](https://console.online.net/) dashboard.

## Setup

Login to [API Access](https://console.online.net/en/api/access) and record your "private access token". You can also generate a new one at will and record that instead. But only the last generated token will work.

## Using the Plugin

Use your token value with the `ONToken` SecureString parameter.

```powershell
$pArgs = @{
    ONToken = (Read-Host "Online.net Token" -AsSecureString)
}
New-PACertificate example.com -Plugin OnlineNet -PluginArgs $pArgs
```
