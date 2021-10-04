# How To Use the Combell DNS Plugin

This plugin works with the [Combell][1] DNS provider. We assume you have already setup an account and have created the
DNS domain zone(s) you'll be working with.

[Combell NV][1] is a hosting provider based in Belgium. Besides offering hosting solutions, Combell NV is also an 
[ICANN Accredited Registrar under IANA number 1467](https://www.icann.org/en/accredited-registrars?sort-direction=asc&sort-param=name&page=1&iana-number=1467&country=Belgium).

## Setup

To use the Combell API, navigate to [Dashboard / Settings / API / Users](https://my.combell.com/en/settings/api/users)
and activate the API key for the required user(s).

## Testing the Plugin

See [Testing Plugins][2] on the Posh-ACME Plugin Development Guide page.

Make sure you have run `Set-ExecutionPolicy RemoteSigned -Scope Process` and `.\instdev.ps1` before you begin testing.

``` powershell
$DebugPreference = 'Continue'
$pArgs = @{
    CombellApiKey = (Read-Host "Combell API key" -AsSecureString)
    CombellApiSecret = (Read-Host "Combell API secret" -AsSecureString)
}

Publish-Challenge example.com (Get-PAAccount) "test-record-1" Combell $pArgs -Verbose
Publish-Challenge example.com (Get-PAAccount) "test-record-2" Combell $pArgs -Verbose
Publish-Challenge example.com (Get-PAAccount) "test-record-3" Combell $pArgs -Verbose

# Check in the Combell "DNS & forwarding management" (https://my.combell.com/en/product/dns) portal whether the test
# records exist. 

Unpublish-Challenge example.com (Get-PAAccount) "test-record-1" Combell $pArgs -Verbose
Unpublish-Challenge example.com (Get-PAAccount) "test-record-2" Combell $pArgs -Verbose
Unpublish-Challenge example.com (Get-PAAccount) "test-record-3" Combell $pArgs -Verbose
```

## Using the Plugin

Your account name/number is used with the `SimplyAccount` parameter. The API key can be used with `SimplyAPIKey` as a SecureString or `SimplyAPIKeyInsecure` as a standard string. The SecureString version should only be used on Windows or any OS with PowerShell 6.2 or later.

### Windows or PS 6.2+

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

[1]: https://www.combell.com/
[2]: https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/#testing-plugins
