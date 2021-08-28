# How To Use the Beget DNS Plugin

This plugin works against the [Beget.com](https://beget.com/) provider. It is assumed that you already have an account and at least one domain you will be working against.

## Setup

It is possible to use this plugin using the same credentials that are used to login to the web control panel. However, it is recommended to setup a separate password for API access and also limit the permissions.

To do this, go to your [Beget API settings](https://cp.beget.com/settings/access/api) and select "Use separate password". After setting the password, uncheck all of the Permitted Methods except for "DNS management" and click the `Apply` button.

**IMPORTANT:** There are some limitations with how the Beget API works that make it risky to use when using [DNS Challenge Aliases](https://github.com/rmbolger/Posh-ACME/blob/main/Tutorial.md#advanced-dns-challenge-aliases). If you need to use this plugin with challenge aliases, the value for the DnsAlias must not contain any other record types or TXT values because they will likely be deleted when the plugin attempts to create the TXT records.

## Using the Plugin

Your Beget credentials are passed as the username and password in a PSCredential object to the `BegetCredential` parameter.

```powershell
$cred = Get-Credential -Message "Beget Credentials"
$pArgs = @{
    BegetCredential = $cred
}
New-PACertificate example.com -Plugin Beget -PluginArgs $pArgs
```
