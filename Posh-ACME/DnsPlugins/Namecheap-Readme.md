# How To Use the Namecheap DNS Plugin

This plugin works against the [Namecheap FreeDNS](https://www.namecheap.com/domains/freedns/) provider. It is assumed that you have already setup an account and registered the domains you will be working against. The domains must not be using custom DNS servers.

## Setup

First, login to your account and go to the [Profile - Tools](https://ap.www.namecheap.com/settings/tools) page. In the "Business & Dev Tools" section, API Access must be turned on. Namecheap seems to require a certain amount of activity (registered domains or money spent) in order to enable API Access. Turning it on requires Namecheap support to authorize and actually enable which can take a couple days.

Once API Access is turned on, click the [Manage](https://ap.www.namecheap.com/settings/tools/apiaccess) button and record your `API Key` value and your Namecheap username. You will also need to whitelist the public IP address of each machine you will be running Posh-ACME from. [whatsmyip.com](https://whatsmyip.com/) can help here if you're behind a NAT router.

## Using the Plugin

There are two parameter sets you can use with this plugin. One is intended for Windows OSes while the other is intended for non-Windows until PowerShell Core fixes [this issue](https://github.com/PowerShell/PowerShell/issues/1654). The non-Windows API Key parameter is called `NCApiKeyInsecure` because the issue prevents PowerShell from encrypting/decrypting SecureString and PSCredential objects.

### Windows

```powershell
$ncKey = Read-Host "API Key" -AsSecureString
$ncParams = @{NCUsername='myusername';NCApiKey=$ncKey}
New-PACertificate test.example.com -DnsPlugin Namecheap -PluginArgs $ncParams
```

### Non-Windows

```powershell
$ncParams = @{NCUsername='myusername';NCApiKeyInsecure='xxxxxxxx'}
New-PACertificate test.example.com -DnsPlugin Namecheap -PluginArgs $ncParams
```
