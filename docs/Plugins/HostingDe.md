title: HostingDe

# How To Use the HostingDe Plugin

This plugin works against the [Hosting.de](https://hosting.de/) provider. It is assumed that you already have an account and at least one managed zone already configured.

## Setup

On your account [profile page](https://secure.hosting.de/profile), click `Create new API key`. Give it a name, and **uncheck** all permissions except "Display" and "Edit" within DNS Service - Zones. Record the value to use later. You won't be able to go back and look it up after leaving the page.

## Using the Plugin

The API key will used with the `HDEToken` parameter as a SecureString value.

```powershell
$pArgs = @{
    HDEToken = (Read-Host 'API Token' -AsSecureString)
}
New-PACertificate example.com -Plugin HostingDe -PluginArgs $pArgs
```
