title: PowerDNS

# How To Use the PowerDNS Plugin

This plugin works against the [PowerDNS](https://www.powerdns.com/powerdns-authoritative-server) Authoritative Server. It is assumed that the server is already running with the DNS zone(s) you will be working against.

## Setup

You'll need to [enable the API](https://doc.powerdns.com/authoritative/http-api/index.html#enabling-the-api) if it hasn't been already. You'll also need the value of the `api-key` setting from the config file.

While PowerDNS doesn't directly support using HTTPS against the API, it's possible to do so by running a reverse proxy in front of it which has the certificate and terminates the TLS connections. Make sure you know the hostname or IP and port number of your server as well as whether you need to use HTTP or HTTPS with the API.

## Using the Plugin

The minimum parameters you need to provide to the plugin are the hostname or IP address using `PowerDNSApiHost` and the API Key as a SecureString parameter using `PowerDNSApiKey`. This will use an API Url assuming default values for server name (`localhost`), port (`8081`), and use HTTP rather than HTTPS.

```powershell
$pArgs = @{
    PowerDNSApiHost = 'pdns.example.com'
    PowerDNSApiKey = (Read-Host "API Key" -AsSecureString)
}
New-PACertificate example.com -Plugin PowerDNS -PluginArgs $pArgs
```

When using an HTTPS reverse proxy in front of the server, you would add `PowerDNSUseTLS`, `PowerDNSPort`, and possibly `PowerDNSServerName` parameters like this:

```powershell
$pArgs = @{
    PowerDNSApiHost = 'pdns.example.com'
    PowerDNSApiKey = (Read-Host "API Key" -AsSecureString)
    PowerDNSUseTLS = $true
    PowerDNSPort = 443
    PowerDNSServerName = 'localhost'
}
New-PACertificate example.com -Plugin PowerDNS -PluginArgs $pArgs
```
