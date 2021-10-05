# How to use the Combell DNS plugin

This plugin works with the [Combell][1] DNS provider. We assume you have already setup an account and have created the
DNS domain zone(s) you'll be working with.

[Combell NV][1] is a hosting provider based in Belgium. Besides offering hosting solutions, Combell NV is also an 
[ICANN Accredited Registrar under IANA number 1467](https://www.icann.org/en/accredited-registrars?sort-direction=asc&sort-param=name&page=1&iana-number=1467&country=Belgium).

See the [Combell API Documentation][2] the [Plugin Development Guide][3] on Posh-ACME Docs for more information.

## Getting started with the Combell DNS plugin

Navigate to the [Dashboard / Settings / API / Users](https://my.combell.com/en/settings/api/users) section and activate
the API key for the required user. Use the API key and API secret found on this page.

## Testing the plugin

See [Testing Plugins][4] on the Posh-ACME Plugin Development Guide page for additional information.

Make sure you have run `Set-ExecutionPolicy RemoteSigned -Scope Process` and `.\instdev.ps1` before you begin testing.

``` powershell
$DebugPreference = 'Continue'
$pArgs = @{
    CombellApiKey = (Read-Host "Combell API key" -AsSecureString)
    CombellApiSecret = (Read-Host "Combell API secret" -AsSecureString)
}

Publish-Challenge example.com (Get-PAAccount) test1 Combell $pArgs -Verbose
Publish-Challenge example.com (Get-PAAccount) test2 Combell $pArgs -Verbose
Publish-Challenge example.com (Get-PAAccount) test3 Combell $pArgs -Verbose

# Now check in the Combell 'DNS & forwarding management' (https://my.combell.com/en/product/dns) portal whether domain
# 'example.com' contains three TXT records with record name '_acme-challenge', each one with a unique content string.

Unpublish-Challenge example.com (Get-PAAccount) test1 Combell $pArgs -Verbose
Unpublish-Challenge example.com (Get-PAAccount) test2 Combell $pArgs -Verbose
Unpublish-Challenge example.com (Get-PAAccount) test3 Combell $pArgs -Verbose
```

## Using the Plugin

Both the API key and API secret can be passed to the plugin as a `SecureString` (use parameters `CombellApiKey` and 
`CombellApiSecret`), or as a standard (and insecure) `String` (use parameters `CombellApiKeyInsecure` and
`CombellApiSecretInsecure`). Always use the `SecureString` on Windows or on any other operating system running
PowerShell 6.2 or later.

Use the `String` versions at your own risk. This is insecure because they will be saved to disk in plaintext by
Posh-ACME for later renewals; see [Parameter Types](https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/#parameter-types)
on the Plugin Development Guide for more information.

### Windows or any other operating system running PowerShell 6.2 or later

``` powershell
$pArgs = @{
    CombellApiKey = (Read-Host "Combell API key" -AsSecureString)
    CombellApiSecret = (Read-Host "Combell API secret" -AsSecureString)
}
New-PACertificate example.com -Plugin Combell -PluginArgs $pArgs
```

### Any other operating system

``` powershell
$pArgs = @{
    CombellApiKeyInsecure = "0123456789abcdef"
    CombellApiSecretInsecure = "*****"
}
New-PACertificate example.com -Plugin Combell -PluginArgs $pArgs
```

## External links

- [Combell.com][1].
- [Combell API Documentation][2].
- [Plugin Development Guide][3]. Posh-ACME Docs.
- [Plugin Development Guide - Testing Plugins][4]. Posh-ACME Docs.

[1]: https://www.combell.com/
[2]: https://api.combell.com/v2/documentation
[3]: https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/
[4]: https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/#testing-plugins
