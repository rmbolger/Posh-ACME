title: Spaceship

# How To Use the Spaceship DNS Plugin

This plugin works against the [Spaceship](https://www.spaceship.com/) domain registrar. It is assumed that you have already setup an account and have the domain registered that you will be working against.

## Setup

- Login to your account and navigate to the [API Manager](https://www.spaceship.com/application/api-manager/).
- If not already enabled, click the `Enable API Access` button.
- Click the `New API Key` button
- Provide a key name and select `Custom Access`
- Disable all permissions except `Read` and `Write` in the `DNS Records` section
- Click `Create API Key`
- Record the short key value and the longer secret value for use with the plugin. The secret value cannot be retrieved later.
- Check the box to confirm you've saved the secret and click `Done`

## Using the Plugin

The API key and secret value will be used as the username and password for the `SpaceshipCredential` plugin parameter which is a PSCredential object.

```powershell
$pArgs = @{
    SpaceshipCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin Spaceship -PluginArgs $pArgs
```
