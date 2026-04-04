title: HostUp

# How To Use the HostUp DNS Plugin

This plugin works against the [HostUp](https://cloud.hostup.se/) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

This plugin works with API Keys. Access tokens are generally preferred because User tokens may have access to multiple accounts. User tokens would only be necessary if the cert you're generating includes names from zones that span multiple accounts.

Login to the [API Management](https://cloud.hostup.se/api-management) section of the dashboard. For API keys:

- Click `Create API Key`
- Give it a name
- Give it the permissions `read:domains`, `read:dns` and `write:dns`
- Click `Create API Key`

After giving the token a name, it will show you the token string. Be sure to save it as you can't look it up if you forget later. You can only generate a new one.

## Using the Plugin

With your token value, you'll need to set the `HUToken` SecureString parameter.

!!! warning
    The `HUTokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    HUToken = (Read-Host "HostUp Token" -AsSecureString)
}
New-PACertificate example.com -Plugin HostUp -PluginArgs $pArgs
```
