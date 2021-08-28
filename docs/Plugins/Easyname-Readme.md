# How To Use the Easyname Plugin

This plugin works against the [Easyname](https://www.easyname.com) hosting provider. It is assumed that you have already setup an account and have at least one domain registered.

> **_NOTE:_** As of April 2021, Easyname's REST API is extremely limited in functionality and doesn't allow for DNS record manipulation. So this plugin utilizes web scraping to accomplish the task. That also means it is more likely to break if the site owner ever changes their HTML markup. So be wary of depending on this for critical projects.

# Setup

Because the plugin uses web scraping to manipulate DNS records, all that is needed is your standard login credentials which should include an email address and password.

## Using the Plugin

Your login credentials should be used with the `EasynameCredential` parameter which is a PSCredential object.

```powershell
$pArgs = @{ EasynameCredential = (Get-Credential) }
New-PACertificate example.com -Plugin Easyname -PluginArgs $pArgs
```
