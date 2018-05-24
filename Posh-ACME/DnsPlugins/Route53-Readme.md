# How To Use the Route53 DNS Plugin

This plugin works against the [AWS Route53](https://aws.amazon.com/route53/) DNS provider. It is assumed that you already have an AWS account with at least one DNS zone, and access to create IAM users/roles. The commands used in this guide will also make use of the [AwsPowershell](https://www.powershellgallery.com/packages/AWSPowerShell) or [AwsPowershell.NetCore](https://www.powershellgallery.com/packages/AWSPowerShell.NetCore) module depending on your environment. Currently, they are also required in order to use the plugin.

## Setup

While you can use an admin level account with Posh-ACME, it's generally a bad practice. So we want to create a dedicated IAM user with minimum necessary privileges to create the TXT records necessary for ACME challenges.

### Setup Admin Credentials

You'll need to create an Access key and associated secret for your account to use with the AwsPowershell module. Once you have those, use the following commands to save them to a local profile and set it as the default credential. If you have previously configured your AWS credentials into a profile via `Set-AWSCredentials`, skip that command below and replace references to the profile name in the `Initialize-AWSDefaultConfiguration` command with your own.

```powershell
Set-AWSCredential -StoreAs 'dnsadmin' -AccessKey 'xxxxxxxx' -SecretKey 'xxxxxxxx'
Initialize-AWSDefaultConfiguration -ProfileName 'dnsadmin'
```

### Create IAM Policy

Create the policy that allows modifications to hosted zones.

```powershell
$policyDef = @{
    Version='2012-10-17';
    Statement=@(
        @{
            Effect='Allow';
            Action=@('route53:ListHostedZones');
            Resource='*';
        },
        @{
            Effect='Allow';
            Action=@(
                'route53:GetHostedZone',
                'route53:ListResourceRecordSets',
                'route53:ChangeResourceRecordSets'
            );
            Resource='arn:aws:route53:::hostedzone/*';
        }
    )
} | ConvertTo-Json -Depth 5; $policyDef

$policy = New-IAMPolicy "R53_Zone_Editor" -PolicyDocument $policyDef -Description "Allow write access to hosted zones."
```

### Create IAM Group and Associate to Policy

Rather than associating the policy to a service account directly, it is wise to associate it to a group instead. That way you can easily add or replace additional users later as necessary.

```powershell
$group = New-IAMGroup -GroupName 'HostedZoneEditors'
Register-IAMGroupPolicy $group.GroupName $policy.Arn
```

### Create IAM User and Add to Group

Finally, we'll create the service account and add it to the group we created. We'll also create the access key to use with the plugin.

```powershell
$user = New-IAMUser -UserName 'posh-acme'
Add-IAMUserToGroup $group.GroupName $user.UserName
$key = New-IAMAccessKey $user.UserName
$key
```

The `$key` variable output should contains `AccessKeyId` and `SecretAccessKey` which are what you ultimately use with the plugin.

## Using the Plugin

There are currently two different ways to use the plugin. The first requires supplying access and secret key to the `R53AccessKey` and `R53SecretKey` parameters. The secret key is a secure string though and takes a bit of extra work to setup. If you lost them, you can re-generate them from the AWS IAM console. But there's no way to retrieve an existing secret key value.

```powershell
# store the secret key as a SecureString
$sec = Read-Host "Secret Key" -AsSecureString

# set the params and generate the cert
$r53Params = @{R53AccessKey='xxxxxxxx';R53SecretKey=$sec}
New-PACertificate test.example.com -DnsPlugin Route53 -PluginArgs $r53Params
```

The second method uses the `R53ProfileName` parameter to specify the profile name of an existing credential stored with `Set-AwsCredential` from the AWS powershell module. **This is also the only method that currently works with PowerShell Core on non-Windows OSes for this plugin.**

```powershell
# store the access/secret key in a profile called 'poshacme'
Set-AWSCredential -StoreAs 'poshacme' -AccessKey 'xxxxxxxx' -SecretKey 'xxxxxxxx'

# set the params and generate the cert
$r53Params = @{R53ProfileName='poshacme'}
New-PACertificate test.example.com -DnsPlugin Route53 -PluginArgs $r53Params
```
