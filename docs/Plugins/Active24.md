title: Active24

# How To Use the Active24 DNS Plugin

This plugin works against the [Active24](https://active24.com) DNS provider. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.


## Setup

First, [login](https://customer.active24.com/) to your account. Tokens are placed at  `Customer data edit` page, in `Tokens management`. There is need to type in your password again to manage the tokens.

### Detailed walk through:
* Using your login information log in to [Customer center](https://customer.active24.com/).
* Click on the **user name** in the upper right corner or you may use direct link to the [API management](http://customer.active24.com/user/api).
* You may **Enter** to the API management at the bottom of this page. 
* Use the **Create a new token** button to setup new API token. 
* The **Comment is not mandatory**, it simply helps to manage created tokens.
* The **expiration date** is also optional.
* In the **Access restrictions** can be specified the IP address of the device that can work with the token. If the device with a different IP address used functional token, it will not perform any requests - the requests cannot be authorized.
* Once you fill everything you need, you can **Create a new token**. There is a **password confirmation** required.


## Using the Plugin

With your token value, you'll need to set the `Token` SecureString parameter.

!!! warning
    The `TokenInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

```powershell
$pArgs = @{
    Token = (Read-Host "Active24 Token" -AsSecureString)
}
New-PACertificate example.com -Plugin Active24 -PluginArgs $pArgs
```