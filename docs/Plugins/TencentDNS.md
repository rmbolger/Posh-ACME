title: TencentDNS

# How To Use the TencentDNS Plugin

This plugin works against [DNSPod](https://dnspod.com/) which is now part of the Tencent Cloud using their v3 API. It is assumed that you have already setup an account and created the domain you will be working against.

## Setup

This plugin works with Tencent Cloud API Keys which is a change from the old DNSPod native plugin that used DNSPod Tokens. Despite what the console says, you cannot use old DNSPod Tokens with this plugin. You will need to generate a new Tencent Cloud API Key if you haven't already.

Login to the console and go to the [Tencent Cloud API Keys](https://console.dnspod.com/account/token/apikey) section. Create a new key and make a note of its ID and Secret values.

## Using the Plugin

The Secret ID is used with the `TencentKeyId` string parameter. The Secret value is used with `TencentSecret` as a SecureString.

```powershell
$pArgs = @{
    TencentKeyId = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    TencentSecret = (Read-Host 'Enter Secret' -AsSecureString)
}
New-PACertificate example.com -Plugin TencentDNS -PluginArgs $pArgs
```
