title: Combell

# How To Use the Combell DNS Plugin

This plugin works with the [Combell][1] DNS provider. We assume you have already setup an account and have created the
DNS domain zone(s) you'll be working with.

[Combell NV][1] is a hosting provider based in Belgium. Besides offering hosting solutions, Combell NV is also an 
[ICANN Accredited Registrar under IANA number 1467](https://www.icann.org/en/accredited-registrars?sort-direction=asc&sort-param=name&page=1&iana-number=1467&country=Belgium).

See the [Combell API Documentation][2] the [Plugin Development Guide][3] on Posh-ACME Docs for more information.

## Setup

Navigate to the [Dashboard / Settings / API / Users](https://my.combell.com/en/settings/api/users) section and activate
the API key for the required user. Use the API key and API secret found on this page in the next section.

## Using the Plugin

Both the API key and API secret have to be passed to the plugin as a `SecureString`, which is supported on Windows
running PowerShell 5.1 or later, or on any other operating system running PowerShell 6.2 or later.

Using `SecureString` ensures the API key and API secret are saved to disk in encrypted form by Posh-ACME for later
renewals.

``` powershell
$pArgs = @{
    CombellApiKey = (Read-Host "Combell API key" -AsSecureString)
    CombellApiSecret = (Read-Host "Combell API secret" -AsSecureString)
}
New-PACertificate example.com -Plugin Combell -PluginArgs $pArgs
```

## External links

- [Combell.com][1].
- [Combell API Documentation][2].
- [Plugin Development Guide][3]. Posh-ACME Docs.

[1]: https://www.combell.com/
[2]: https://api.combell.com/v2/documentation
[3]: https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/
