# How To Use the Plesk DNS Plugin

This plugin works with [Plesk](https://www.plesk.com/), which is a web hosting and server data center automation software. It is assumed you have already setup your server(s) and are properly serving the necessary Internet facing DNS zones for the certificates you will request.

## Setup
Ensure the REST API is enabled (default) and obtain an API key.  See [Plesk REST API Documentaion](https://docs.plesk.com/en-US/obsidian/api-rpc/about-rest-api.79359/) for additional information.

## Using the Plugin

The parameter `PleskUrl` needs to be set to the root URL of your Plesk server, such as `https://plesk01.example.com:8443`.   
It is also mandatory to provide the previouisly obtained API key as the `PleskToken` (SecureString) or `PleskTokenInsecure` (PlainText) parameter.  
The SecureString option may only be used on Windows or any OS with PowerShell 6.2 or later.

### SecureString (Windows and/or PS 6.2+ only)

```powershell
$apiToken = Read-Host "API Token" -AsSecureString

$pArgs = @{
    PleskUrl = 'https://plesk01.example.com:8443';
    PleskToken = $apiToken
}
New-PACertificate example.com -DnsPlugin PleskDNS -PluginArgs $pArgs
```

### PlainText (Any OS)

```powershell
$pArgs = @{
    PleskUrl = 'https://plesk01.example.com:8443';
    PleskTokenInsecure = '78711059-23bb-cf6f-b07f-985e1995d2e2'
}
New-PACertificate example.com -DnsPlugin PleskDNS -PluginArgs $pArgs
```