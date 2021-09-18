title: ISPConfig

# How To Use the ISPConfig DNS Plugin

This plugin works against the [ISPConfig](https://www.ispconfig.org/) hosting control panel. It is assumed that you have an account and created the DNS zone(s) you will be working against.

## Setup

As an admin account, go to `System - Remote Users` and create a new remote user with the following permissions:

- Remote Access
- (Optional) Remote Access IPs
- Client functions
- DNZ zone functions
- DNS txt functions

In addition to the credentials for the remote user, you will need to know the URL for the JSON REST endpoint. You should be able to derive it by using the URL of the control panel home page. Just replace `index.php` with `remote/json/php`. For example:

- Homepage: https://ispc.example.com:8080/index.php
- JSON Endpoint: https://ispc.example.com:8080/remote/json.php

## Using the Plugin

The remote access username and password are used the the `ISPConfigCredential` parameter as a PSCredential object. The JSON endpoint is used with the `ISPConfigEndpoint` parameter. If your control panel is currently using a self-signed certificate, you may also need to use `ISPConfigIgnoreCert=$true`.

```powershell
$pArgs = @{
    ISPConfigCredential = (Get-Credential)
    ISPConfigEndpoint = 'https://ispc.example.com:8080/remote/json.php'
    ISPConfigIgnoreCert = $true
}
New-PACertificate example.com -Plugin ISPConfig -PluginArgs $pArgs
```
