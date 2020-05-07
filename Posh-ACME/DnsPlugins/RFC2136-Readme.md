# How to use the RFC2136 Plugin

This plugin works against any DNS provider that supports dynamic updates using the protocol specified in [RFC 2136](https://tools.ietf.org/html/rfc2136). Both unauthenticated and TSIG authenticated updates are supported.

## Setup

It is beyond the scope of this guide to explain how to configure your DNS server to accept dynamic updates or generate a TSIG key to use for authentication. But if you're using BIND, the [Dynamic Update Policies](https://bind9.readthedocs.io/en/latest/reference.html#dynamic-update-policies) section of the official docs is a good place to start. There are also a variety of tutorials available with a quick web search.

The plugin does not currently support Kerberos (GSS-TSIG) based updates. You must either use unauthenticated updates with an IP whitelist or TSIG authenticated updates using a key type supported by your DNS server and the `nsupdate` utility. As of this writing, the current stable version of BIND is 9.16.1 and supports key types using the following algorithms:

- `hmac-md5`
- `hmac-sha1`
- `hmac-sha224`
- `hmac-sha256`
- `hmac-sha384`
- `hmac-sha512`

When using a TSIG key, you will typically have 3 values; a key name, a key type from the list above, and a Base64 encoded key value. You will need to supply all three as plugin parameters.

### Plugin Dependencies

Due to the inexplicable lack of good native DNS libraries within PowerShell/.NET, this plugin relies on the `nsupdate` utility which is part of the ISC BIND distribution. Most modern Linux distributions will have this installed by default, but double check to be sure. **On Windows, you will need to download and install the utility.** Go to the [ISC BIND Downloads](https://www.isc.org/download/) page and download the current stable version for Windows. You don't actually need to run the installer. It is sufficient to simply unzip the archive and either add that folder to your `PATH` environment variable or specify the full path to `nsupdate.exe` in the plugin arguments. *(Adding the folder to your PATH also gives you easy access to the `dig` utility which many DNS admins prefer over nslookup)*

## Using the Plugin

When using unauthenticated updates, the only required parameter is `DDNSNameserver` which is the IP or hostname of the authoritative DNS server that will accept dynamic updates for the zone your TXT record lives in. You may also provide `DDNSPort` if your server is not listening on the standard port 53.

When using TSIG authenticated updates, in addition to the previous parameters you must also supply `DDNSKeyName`, `DDNSKeyType`, and one of two methods to provide the key value. The `DDNSKeyValue` parameter is a SecureString object which can only be used from Windows or any OS with PowerShell 6.2 or later. The other option is `DDNSKeyValueInsecure` which is a standard String.

If the `nsupdate` utility is not in your PATH environment variable, you must also supply the full path to it using the `DDNSExePath` parameter.

Here are a few examples using different combinations of parameters.

### Windows or PowerShell 6.2+ with TSIG and explicit nsupdate path

```powershell
$keyVal = Read-Host 'TSIG Key Value' -AsSecureString
$params = @{
    DDNSNameserver = 'ns.example.com'
    DDNSKeyName = 'mykey'
    DDNSKeyType = 'hmac-sha256'
    DDNSKeyValue = $keyVal
    DDNSExePath = 'C:\BIND\nsupdate.exe'
}
New-PACertificate example.com -DnsPlugin RFC2136 -PluginArgs $params
```

### Any OS with TSIG and nsupdate in PATH

```powershell
$params = @{
    DDNSNameserver = 'ns.example.com'
    DDNSKeyName = 'mykey'
    DDNSKeyType = 'hmac-sha256'
    DDNSKeyValueInsecure = 'bgBvAHQAIABhACAAcgBlAGEAbAAgAGsAZQB5AA=='
}
New-PACertificate example.com -DnsPlugin RFC2136 -PluginArgs $params
```

### Any OS with unauthenticated update and alternate port

```powershell
$params = @{DDNSNameserver='ns.example.com'; DDNSPort=54}
New-PACertificate example.com -DnsPlugin RFC2136 -PluginArgs $params
```
