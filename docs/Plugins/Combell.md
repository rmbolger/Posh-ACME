title: Combell

# How To Use the Combell DNS Plugin

[Combell NV][1] is a hosting provider based in Belgium. Besides offering hosting solutions, Combell NV is an 
[ICANN Accredited Registrar under IANA number 1467](https://www.icann.org/en/accredited-registrars?sort-direction=asc&sort-param=name&page=1&iana-number=1467&country=Belgium).

This plugin works with the [Combell][1] DNS provider by using the Combell Reseller API.

| **:warning: WARNING** | The Combell Reseller API (also referred to as the _Combell API_), is _only_ available for reseller accounts, which are more expensive than normal accounts. A free trial is available - see [reseller hosting](https://www.combell.com/en/reseller-hosting) for more information. ―Steven Volckaert, 12 October 2021. |
| :---: | :--- |

The remainder of this document assumes you have a reseller account and have created the DNS domain zone(s) you'll be
working with.

## Setup

The Combell API can be activated for any administrator in the Combell reseller account.

To add administrators, navigate to [Dashboard / Settings / Administrators](https://my.combell.com/en/user-management/administrators), and click the **Invite administrator** button to add an administrator.

Click the **Permissions** button next to an administrator's name, and ensure the administrator's permssions is configured as **All rights** (_"User <UserName> has access to all the products in this customer account"_).

Next, navigate to [Dashboard / Settings / API / Users](https://my.combell.com/en/settings/api/users) and activate the
API key for the required administrator(s):
- Click the **API key** button next to the administrator's user name;
- Click the **Activate the API key** button (_"Activate an API key for this user."_);

The API key and API secret will now appear. You'll need them in the next section **Using the Plugin**.

### IP address whitelisting

The Combell API can only be accessed from registered IP addresses.

Navigate to [Dashboard / Settings / API / IP restrictions](https://my.combell.com/en/settings/api/ip-restrictions) and
add your public IP address(es) to the whitelist.

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
