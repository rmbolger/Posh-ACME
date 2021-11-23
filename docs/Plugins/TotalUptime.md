title: TotalUptime

# How To Use the TotalUptime Cloud DNS Plugin

This plugin works against the [TotalUptime](https://totaluptime.com/solutions/cloud-dns-service/) Cloud DNS Service. It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

## Setup

In order to use the TotalUptime Cloud DNS Plugin you will need an to create an API Account with a Role permitting access to DNS

### Create role

* In account settings go to the `Roles & Security` tab
* Add a role with `DNS` Enabled, `DNS/Information` Read, and `DNS/Domains` Full

For further information refer to the documentation at: [Add a Role](https://totaluptime.com/manual/account-admin/roles-security-tab/add-a-role/)


### Create API Account

* In account settings go to the `Users` tab
* Add a User checking the `API Account` box with the role you created earlier

For further information refer to the documentation at: [Add a User](https://totaluptime.com/manual/account-admin/users-tab/add-a-user/)

## Using the Plugin

You will need to specify the API account username and password in a PSCredentials object in `TotalUptimeCredential`

```powershell
$pArgs = @{
    TotalUptimeCredential = (Get-Credential)
}
New-PACertificate example.com -Plugin TotalUptime -PluginArgs $pArgs
```
