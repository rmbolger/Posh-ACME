title: AddrTools

# How To Use the AddrTools DNS Plugin

This plugin works against [challenges.addr.tools](https://challenges.addr.tools/) which is a specialized provider purpose built for validating dns-01 challenges using CNAME aliases. It is part of the larger [addr.tools](https://www.addr.tools/) open source project which means you can self-host your own instance. But the default configuration works against the author's public instance.

## Setup

It may help to read the [Using DNS Challenge Aliases](../Guides/Using-DNS-Challenge-Aliases.md) guide to better understand how CNAME records work with ACME challenges. Most importantly, there will be a one-time CNAME record creation for each name in the certificate you are requesting.

There is a helper function in the plugin to help determine which CNAME records to create. It uses the same parameters that the AddrTools plugin uses. So use the following code to create an appropriate `$pArgs` variable and a `$domains` variable that contains the list of domains in your certificate.

```powershell
$pArgs = @{
    AddrToolsSecret = Read-Host -Prompt "Enter Secret" -AsSecureString
    AddrToolsHost = 'challenges.addr.tools' # optional unless self-hosting
}
$domains = 'example.com','www.example.com'
```

Now run the following to load and run the helper function that will tell you what CNAME records to create.

```powershell
Import-Module Posh-ACME
. (Join-Path (Get-Module Posh-ACME).ModuleBase "Plugins\AddrTools.ps1")
Get-AddrToolsCNAME $domains @pArgs
```

The output will look similar to this depending on how many unique domains you have:

```
FQDN                            Target
----                            ------
_acme-challenge.example.com     7870508034f01f4a28d86812fa7bd10a03cb7e7e6ddda0ddb95ff771.challenges.addr.tools
_acme-challenge.www.example.com 7870508034f01f4a28d86812fa7bd10a03cb7e7e6ddda0ddb95ff771.challenges.addr.tools
```

## Using the Plugin

Once all necessary CNAME records are created, you can use the same `$pArgs` value from setup with the plugin. `AddrToolsSecret` is always required and `AddrToolsHost` is only required if you're self-hosting your own instance at a different domain.

You'll also need to use the `-DnsAlias` parameter from New-PACertificate with the Target value from the CNAME records.

```powershell
# set this to the CNAME Target value from setup
$target = 'xxxxxxxxxxxxxxxxxx.challenges.addr.tools'

$pArgs = @{
    AddrToolsSecret = (Read-Host 'Access Token' -AsSecureString)
}
New-PACertificate example.com -Plugin AddrTools -PluginArgs $pArgs -DnsAlias $target
```
