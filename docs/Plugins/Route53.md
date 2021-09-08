title: Route53

# How To Use the Route53 DNS Plugin

This plugin works against the [AWS Route53](https://aws.amazon.com/route53/) DNS provider. It is assumed that you already have an AWS account with at least one DNS zone. The setup portion of this guide also assumes you have access to create IAM users/roles. If you have been given access credentials by your AWS admin, you may need the admin to create the IAM policies necessary for you to edit the zone TXT records.

!!! note
    You may use this plugin without the AWS PowerShell module installed *unless* you use the profile name authentication method. In that case, you will either need the [Aws.Tools.Route53](https://www.powershellgallery.com/packages/AWS.Tools.Route53/) or the older [AWSPowerShell](https://www.powershellgallery.com/packages/AWSPowerShell) or [AWSPowerShell.NetCore](https://www.powershellgallery.com/packages/AWSPowerShell.NetCore) module depending on your environment. More details can be found in the [AWS PowerShell documentation](https://docs.aws.amazon.com/powershell/).

## Setup

There are generally two different ways to use this plugin depending on whether you are running it from outside AWS or inside from something like an EC2 instance. When outside, you need to specify explicit credentials for an IAM account that has permissions to modify a zone. When inside, you may instead choose to authenticate using an [IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html). When using explicit credentials, a personal high-level account will work, but it's a better idea to create a dedicated user with the minimum necessary privileges to create the TXT records necessary for ACME challenges.

If you already have your policies, users, groups, and roles setup, skip the rest of this section. Otherwise, read on for examples.

!!! note
    These examples require either the [AWS.Tools.IdentityManagement](https://www.powershellgallery.com/packages/AWS.Tools.IdentityManagement) module or the older [AWSPowerShell](https://www.powershellgallery.com/packages/AWSPowerShell) or [AWSPowerShell.NetCore](https://www.powershellgallery.com/packages/AWSPowerShell.NetCore) module depending on your environment.

### Setup Admin Credentials

You'll need to create an Access key and associated secret for your account to use with the AWS module. Once you have those, use the following commands to save them to a local profile and set it as the default credential. If you have previously configured your AWS credentials into a profile via `Set-AWSCredentials`, skip that command below and replace references to the profile name in the `Initialize-AWSDefaultConfiguration` command with your own.

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

### If Using Explicit Credentials

#### Create IAM Group and Associate to Policy

Rather than associating the policy to a service account directly, it is wise to associate it to a group instead. That way you can easily add or replace additional users later as necessary.

```powershell
$group = New-IAMGroup -GroupName 'HostedZoneEditors'
Register-IAMGroupPolicy $group.GroupName $policy.Arn
```

#### Create IAM User and Add to Group

Finally, we'll create the service account and add it to the group we created. We'll also create the access key to use with the plugin.

```powershell
$user = New-IAMUser -UserName 'posh-acme'
Add-IAMUserToGroup $group.GroupName $user.UserName
$key = New-IAMAccessKey $user.UserName
$key
```

The `$key` variable output should contains `AccessKeyId` and `SecretAccessKey` which are what you ultimately use with the plugin.

### If Using IAM Role

#### Create IAM Role and Associate to Policy

If your server that is using Posh-ACME lives within AWS (such as an EC2 instance), you can create an [IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) and associate it to the instance which then avoids the need to use and store explicit credential for Route53. Here's how you might create the role and associate it with the policy created earlier.

```powershell
$roleTrust = @{
    Version='2012-10-17'
    Statement=@(
        @{
            Effect='Allow'
            Action='sts:AssumeRole'
            Principal=@{
                Service='ec2.amazonaws.com'
            }
        }
    )
} | ConvertTo-Json -Depth 5; $roleTrust

$role = New-IAMRole -RoleName 'R53_Zone_Editor_Role' -AssumeRolePolicyDocument $roleTrust -Description 'Allows associated EC2 instances to modify Route53 zones for certificate validation purposes.'

Register-IAMRolePolicy $role.RoleName $policy.Arn
```

Now you'd need to attach the role with your EC2 instance or launch a new instance with the role pre-attached. More details on that can be found [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html).


## Using the Plugin

If you are using explicit credentials, you may send them directly to the plugin via `R53AccessKey` and `R53SecretKey` parameters. A SecureString value is required for `R53SecretKey`. If you lost the keys, you can re-generate them from the AWS IAM console. But there's no way to retrieve an existing secret key value.

!!! warning
    The `R53SecretKeyInsecure` parameter is deprecated and will be removed in the next major module version. If you are using it, please migrate to the Secure parameter set.

### Explicit Credentials

```powershell
$pArgs = @{
    R53AccessKey = 'xxxxxxxx'
    R53SecretKey = (Read-Host "Secret Key" -AsSecureString)
}
New-PACertificate example.com -Plugin Route53 -PluginArgs $pArgs
```

### AWS Powershell Module Profile

You may also use the `R53ProfileName` parameter to specify the profile name of an existing credential stored with `Set-AwsCredential` from an AWS powershell module. Remember that the module must remain installed for renewals when using this method.

```powershell
# store the access/secret key in a profile called 'poshacme'
Set-AWSCredential -StoreAs 'poshacme' -AccessKey 'xxxxxxxx' -SecretKey 'yyyyyyyy'

# set the params and generate the cert
$pArgs = @{R53ProfileName='poshacme'}
New-PACertificate example.com -Plugin Route53 -PluginArgs $pArgs
```

### IAM Role

When using an IAM Role, the only thing you need to specify is a switch called `R53UseIAMRole`.

```powershell
New-PACertificate example.com -Plugin Route53 -PluginArgs @{R53UseIAMRole=$true}
```
