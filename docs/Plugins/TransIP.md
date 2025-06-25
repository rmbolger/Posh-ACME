title: TransIP

# How To Use the TransIP Plugin

This plugin works against the [TransIP](https://www.transip.nl) domain registrar and its associated alternate TLDs. It is assumed that you have already setup an account and registered the domain you will be working against.

## Setup

Login to your TransIP Control Panel and navigate to the API section. API access is authenticated using an RSA private key that can optionally be restricted to an IP whitelist.

If you wish to enforce IP whitelisting on the server side, add the associated address or ranges to the list. Then create a new Key Pair with the box checked to enforce IP whitelisting. Finally, save the displayed value to a file for later.

If you don't want to enforce IP whitelisting or want to leave the enforcement up to the client, don't check the box when creating the key pair.

It is also possible to use the plugin with a pre-authenticated access token. But they are time limited and would require manual intervention during renewal or external automation to retrieve an updated token.

## Using the Plugin

When using the typical key based authentication, the private key you created can be referenced as a file path using the `TIPKeyPath` parameter or as a SecureString value using the `TIPKeyText` parameter. If using TIPKeyPath, the file must remain in the same location for renewals. You must also supply your Control Panel username using the `TIPUsername` parameter. If the IP whitelisting box was not checked when you created the key, you may also use the `TIPEnforceWhitelist` switch to enable that enforcement.

```powershell
$keyText = Read-Host -AsSecureString # this will prompt for your key
$pArgs = @{
    TIPUsername = 'myuser'
    TIPKeyText = $keyText
}
New-PACertificate example.com -Plugin TransIP -PluginArgs $pArgs
```

When using a pre-authenticated access token, you may supply that using the `TIPAccessToken` string parameter.

```powershell
$accessToken = Read-Host # this will prompt for your access token
$pArgs = @{
    TIPAccessToken = $accessToken
}
New-PACertificate example.com -Plugin TransIP -PluginArgs $pArgs
```
