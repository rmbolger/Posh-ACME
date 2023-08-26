title: ZoneEdit

# How To Use the ZoneEdit Plugin

This plugin works against [ZoneEdit](https://www.zoneedit.com/). You should already have an account and created the DNS zone(s) you will be working against.

## Setup

The plugin works using a variation on the standard Dynamic DNS service. Each domain you will be using the plugin with must have a Dynamic Authentication Token created for it.

- Login to the [Domains control panel](https://cp.zoneedit.com/manage/domains/)
- Open the DNS settings for the domain
- Click the wrench icon in the `DYN records` section
- At the bottom in the `dynamic authentication` section, click `enable` if is not already
- Then click `view` to view the current token
- Make a note of the token value and the domain it is associated with.

## Using the Plugin

You will always provide your account username in the `ZEUsername` string parameter. If the names in your certificate are all part of the same domain, you will need to provide a PSCredential object to the `ZEDynCredential` parameter where the domain name is the username and the token is the password.

```powershell
$domainToken = Read-Host 'example.com' -AsSecureString

$pArgs = @{
    ZEUsername = 'myuser'
    ZEDynCredential = [pscredential]::new('example.com',$domainToken)
}
New-PACertificate 'example.com','www.example.com' -Plugin ZoneEdit -PluginArgs $pArgs
```

If the names in your cert are part of different domains, you'll need to provide an array of PSCredential objects for each domain/token combination that the names cover.

```powershell
$token1 = Read-Host 'example.com' -AsSecureString
$token2 = Read-Host 'example.net' -AsSecureString

$pArgs = @{
    ZEUsername = 'myuser'
    ZEDynCredential = @(
        [pscredential]::new('example.com',$token1)
        [pscredential]::new('example.net',$token2)
    )
}
New-PACertificate 'example.com','example.net' -Plugin ZoneEdit -PluginArgs $pArgs
```
