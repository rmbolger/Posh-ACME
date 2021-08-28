title: Constellix

# How To Use the Constellix Plugin

This plugin works against the [Constellix DNS](https://constellix.com/) provider. It is assumed that you already have an account and at least one managed zone already configured.

## Setup

While you can use an account with the "Admin" role, it is not recommended for security reasons. Instead, you should create an account from the [User Management Console](https://manage.constellix.com/users) with the "User" role and limit it to the DNS service on the account. Then, go to the [DNS Users Console](https://dns.constellix.com/users) and modify the `Domains` permissions to include:

- (Optional) New domain permissions on creation: `Read/Write/Commit`. *If you leave this on `None`, you will need to manually give permissions to future domains when they are created.*
- Uncheck "Add Domains"
- Uncheck "Delete Domains"
- `Read/Write/Commit` on either "All Domains" or a selected subset of domains you will be using Posh-ACME with.

Now login to the management console as the user who will be using Posh-ACME and go to [Edit My Info](https://manage.constellix.com/user). Click the `Generate API Keys` button and record the values for "API Key" and "Secret Key". This is the only time they will be displayed.

## Using the Plugin

The API key will used with the `ConstellixKey` parameter as a string value. The API secret will be used with the `ConstellixSecret` parameter as a SecureString value.

```powershell
$secret = Read-Host -Prompt 'API Secret' -AsSecureString
$pArgs = @{
    ConstellixKey = 'xxxxxxxxxxxx'
    ConstellixSecret = $secret
}
New-PACertificate example.com -Plugin Constellix -PluginArgs $pArgs
```
