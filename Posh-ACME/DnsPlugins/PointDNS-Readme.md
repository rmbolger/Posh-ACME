# How to use the PointDNS DNS Plugin

This plugin works against the [PointDNS](https://pointhq.com) DNS provider. It presumes
that you have already set up an account and created the DNS zone(s) that you are targeting.

### Setup

[Login](https://app.pointhq.com/verify) to your account. Go to `Account` and copy
your API key. Click the key icon if you need to generate a new key.

### Using the Plugin

Once you have your key value, you'll need to set either `PDKey` or `PDKeyInsecure` in
the plugin parameters. `PDKey` is a [SecureString](https://docs.microsoft.com/en-us/dotnet/api/system.security.securestring) 
and may not work properly on non-Windows hosts. If `PDKey` doesn't work for you,
please use `PDKeyInsecure`. In addition to the key / token value, you'll need to submit your
user email address as the `PDUser` parameter.

### Examples

```powershell
$token = Read-Host "PointDNS Key" -AsSecureString
New-PACertificate test.example.com -DnsPlugin PointDNS -PluginArgs @{PDUser='email@example.com';PDKey=$token}
```

With insecure token string

```powershell
New-PACertificate test.example.com -DnsPlugin PointDNS -PluginArgs @{PDUser='email@example.com';PDKeyInsecure='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'}
```