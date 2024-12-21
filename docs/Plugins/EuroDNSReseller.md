title: EuroDNSReseller

# How To Use the EuroDNSReseller DNS Plugin

This plugin works with the [EuroDNS](https://www.eurodns.com/) DNS provider. While it is possible to purchase domains directly from EuroDNS, their APIs are currently only available to [Reseller Partners](https://www.eurodns.com/partners). Some of those partners such as [EBrand](https://ebrand.com) can provide EuroDNS API access to their customers. So in order to use this plugin, you will need to be using a reseller that will create API credentials for you.

!!! note
    As of November 2024, EuroDNS support has indicated the API (or perhaps a new API) will eventually be available for all direct customers. However, they would not provide an estimate for when that might be available.

## Setup

Setup involves getting API credentials from your reseller which will vary depending on the reseller. The values you need are known as `X-APP-ID` and `X-API-KEY`.

## Using the Plugin

The `X-APP-ID` and `X-API-KEY` will be used as the username and password in a PSCredential object called `EuroDNSReseller_Creds`.

Here are two examples on how you can use them:

```powershell
# Prompt for the credentials where username is X-APP-ID
# and password is X-API-KEY
$pArgs = @{EuroDNSReseller_Creds = Get-Credential}

New-PACertificate example.com -Plugin EuroDNSReseller -PluginArgs $pArgs
```

For a more automated approach (This method assumes you understand the risks and methods to secure the below credentials):

```powershell
$username = "My_X-APP-ID_Value"
$password = "My_X-API-Key_Value" | ConvertTo-SecureString -AsPlainText -Force
$cred = [pscredential]::new($username, $password)
$pArgs = @{EuroDNSReseller_Creds = $cred}

New-PACertificate example.com -Plugin EuroDNSReseller -PluginArgs $pArgs
```
