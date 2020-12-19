# How To Use the Aliyun (Alibaba Cloud) DNS Plugin

This plugin works against the [Aliyun (Alibaba Cloud)](https://www.alibabacloud.com/product/dns) DNS provider. It is assumed that you have already setup an account and registered the domains or zones you will be working against.

## Setup

First, login to your account and go to the [Security Management](https://usercenter.console.aliyun.com/#/manage/ak) page. Click the `Create Access Key` link and make a note of the Key ID and Secret values.

**Note:** It is also supported recommended to use RAM (Resource Access Management) users with more limited privileges instead of your root account key. More information about creating RAM users can be found [here](https://www.alibabacloud.com/help/product/28625.htm).

## Using the Plugin

There are two parameter sets you can use with this plugin. One requires being on Windows or any OS with PowerShell 6.2 or later due to a previous PowerShell [bug](https://github.com/PowerShell/PowerShell/issues/1654). The other can be used from any OS.

### Windows or PS 6.2+

```powershell
$secret = Read-Host "Secret" -AsSecureString
$aliParams = @{AliKeyId='asdf1234';AliSecret=$secret}
New-PACertificate example.com -Plugin Aliyun -PluginArgs $aliParams
```

### Any OS

```powershell
$aliParams = @{AliKeyId='asdf1234';AliSecretInsecure='xxxxxxxx'}
New-PACertificate example.com -Plugin Aliyun -PluginArgs $aliParams
```
