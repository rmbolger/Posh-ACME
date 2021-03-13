# How To Use the Simple DNS Plus Plugin

This plugin works with [Simple DNS Plus](https://simpledns.com/) which is a self-hosted DNS server for Windows. It is assumed you have already setup your server(s) and are properly serving the necessary Internet facing DNS zones for the certificates you will request.

## Setup

Enable the HTTP API in the server options dialog

- In the main window
- Click `Tools`
- Click `Options`
- On the left, Scroll down and click `HTTP API`
- Make sure `Enable HTTP API` is checked
- Leave the URL prefix as default or set a custom one (e.g. https://dns.example.com:443/api).
  - If you use HTTPS for the URL prefix, make sure to follow this guide to setup the certificate properly: [How to bind an SSL certificate to the HTTP API](https://simpledns.com/kb/163/how-to-bind-an-ssl-certificate-to-the-http-api)
- Select your desired Authentication method.
  - Anonymous is supported, but not recommended from a security standpoint.
  - Basic is recommended and fully supported on all platforms. It is *highly* recommended to configure HTTPS when using Basic authentication. You can either use embedded credentials or Windows account credentials.
  - Digest authentication is not officially supported, but can work in some environments.
  - NTLM\Kerberos is not officially supported, but can work in some environments.
- Make a note of the credentials for later.
- The CORS setting is irrelevant for using the plugin. But enabling it can be useful for general HTTP API testing.
- You don't need to enable the HTTP API v.1 check box. But if you do, remember to add a `/v2` to your `SdnsApiRoot` property later.
- Click `OK`

## Using the Plugin

The primary parameter you need with this plugin is `SdnsApiRoot` which is the root URL for the HTTP API such as `http://dns.example.com:8053`. Remember to add a `/v2` if you enabled the API v.1 check box. If you're using HTTPS and a self-signed certificate, you'll also need to add the `SdnsIgnoreCert` parameter.

If you're not using anonymous authentication, you'll also need to specify credentials either as a PSCredential object with `SdnsCred` or plain text credentials with `SdnsUser` and `SdnsPassword`. The PSCredential option may only be used on Windows or any OS with PowerShell 6.2 or later.

### Anonymous Authentication

```powershell
$pArgs = @{
    SdnsApiRoot = 'http://dns.example.com:8053'
    SdnsIgnoreCert = $true
}
New-PACertificate example.com -Plugin SimpleDNSPlus -PluginArgs $pArgs
```

### Secure Credential Authentication (Windows and/or PS 6.2+ only)

```powershell
$pArgs = @{
    SdnsApiRoot = 'http://dns.example.com:8053'
    SdnsIgnoreCert = $true
    SdnsCred = (Get-Credential)
}
New-PACertificate example.com -Plugin SimpleDNSPlus -PluginArgs $pArgs
```

### Plain Text Username/Password Authentication

```powershell
$pArgs = @{
    SdnsApiRoot = 'http://dns.example.com:8053'
    SdnsIgnoreCert = $true
    SdnsUser = 'admin'
    SdnsPassword = 'xxxxxxxx'
}
New-PACertificate example.com -Plugin SimpleDNSPlus -PluginArgs $pArgs
```
