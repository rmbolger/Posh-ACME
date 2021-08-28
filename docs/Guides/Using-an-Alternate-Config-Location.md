# Using an Alternate Config Location

As of version 3.2.0, you can now configure Posh-ACME to use a different config location than the default path in the current user's profile folder. To do so, set an environment variable called `POSHACME_HOME` prior to running `Import-Module` or calling your first function. This can be done directly in the PowerShell session or any other standard way of setting environment variables in your OS or config management system. If the module was already imported before setting the environment variable, re-import with the `-Force` parameter to pick up the new location.

```powershell
$env:POSHACME_HOME = 'C:\my\path'
Import-Module Posh-ACME -Force
```

## Why Bother?

The default config location is specific to the OS the module is running on.

- Windows: `%LOCALAPPDATA%\Posh-ACME`
- Linux: `$HOME/.config/Posh-ACME`
- MacOS: `$HOME/Library/Preferences/Posh-ACME`

While the default config location is fine for most standard use-cases, there are legitimate reasons to host the config in a more central location. A common one is to enable multiple different users to manage certificates. Another might simply be easier integration with the application using the certificate.

## IMPORTANT: Encrypted Plugin Parameters

On Windows OSes, most DNS plugins default to using "secure" versions of various plugin parameters like passwords and API tokens. When saved to disk, these secure parameters are encrypted so only the current user on the current computer can decrypt them. If you are using an alternate config location so that multiple users on the system can manage certificates, this can cause errors if a user tries to decrypt something that was encrypted by another user.

In Posh-ACME 4.x, you have a few options to workaround this limitation.

1. On each ACME account, use portable AES encryption instead of the OS native encryption with the `-UseAltPluginEncryption` switch on either `New-PAAccount` or `Set-PAAccount`.

2. Don't use any plugin parameters that are `[SecureString]` or `[PSCredential]` types. Most plugins have "Insecure" versions of the normally secure arguments that are not encrypted on disk. However, these insecure parameter sets are deprecated and may be removed in a future major version of the module.

3. Have each user on the system create their own ACME account that only they will use. This will technically prevent the errors as long as people don't try to accidentally renew or create new order from the wrong account. But it's not recommended.

In Posh-ACME 3.x and earlier, you must either use option 2 or 3.
