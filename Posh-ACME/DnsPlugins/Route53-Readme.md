# How To Use the Azure DNS Plugin

This plugin works against the [AWS Route53](https://aws.amazon.com/route53/) DNS provider. It is assumed that you already have an AWS account with at least one DNS zone, and access to create IAM users/roles. The commands used in this guide will also make use of the [AwsPowershell](https://www.powershellgallery.com/packages/AWSPowerShell) module. Currently, it is also required in order to use the plugin.

## Setup

While you can use an admin level account with Posh-ACME, it's generally a bad practice. So we want to create a dedicated IAM user with only enough privileges to create the TXT records necessary for ACME challenges.

### Setup Admin Credentials

You'll need to create an Access key and associated secret for your account to use with the AwsPowershell module. Once you have those, use the following commands to save them to a local profile and set it as the default credential. If you have previously configured your AWS credentials into a profile via `Set-AWSCredentials`, skip that command below and replace references to the profile name in the `Initialize-AWSDefaultConfiguration` command with your own.

```powershell
Set-AWSCredential -StoreAs 'dnsadmin' -AccessKey 'xxxxxxxx' -SecretKey 'xxxxxxxx'
Initialize-AWSDefaultConfiguration -ProfileName 'dnsadmin'
```

## Using the Plugin

TODO
