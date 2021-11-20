# Using SecretManagement

The alternative plugin encryption option added in Posh-ACME 4.0 allows for encrypting secure plugin arguments on disk with better config portability between users/systems and improves the encryption available on non-Windows platforms. The only downside to the feature is that the encryption key was stored with the main config which enables anyone with read access to the files the ability to decrypt the plugin parameters.

In Posh-ACME 4.11.0, you can now utilize the Microsoft [SecretManagement](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/) module to store the encryption key in a variety of local, on-prem, and cloud secret stores using supported [vault extensions](https://www.powershellgallery.com/packages?q=Tags%3A%22SecretManagement%22).

!!! warning
    Some vault extensions are read-only and don't allow for creation of new secrets. The vault extensions supported by Posh-ACME must allow for secret creation using arbitrary name values.

## Prerequisites

In order to use the SecretManagement feature, you must install both the [Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement/) module and an appropriate vault extension module to interface with your preferred secret store.

You will also need to register a new vault and make note of the vault name. It will be provided to Posh-ACME using the `POSHACME_VAULT_NAME` environment variable.

### Vault Password

Some vaults can be configured with a password such that retrieving a secret requires first unlocking the vault with the password. In order to use a vault with Posh-ACME, you have three options.

- Configure the vault so a password is not required.
- Provide the vault password using the `POSHACME_VAULT_PASS` environment variable.
- Prior to calling Posh-ACME functions, unlock or pre-authenticate to the vault so Posh-ACME can call `Set-Secret` and `Get-Secret` without error.

### Secret Names and Customization

Each account configured to use alternative plugin encryption will store a single secret in the vault. The name of each secret will use the following template:

> `poshacme-{0}-sskey`

The `{0}` is replaced with a unique GUID value generated for each account the first time the feature is used and stored as a property called `VaultGuid` on the account object. This ensures that using the same vault for multiple accounts does not result in secret naming conflicts.

You may optionally create an environment variable called `POSHACME_VAULT_SECRET_TEMPLATE` to override the default template. Be sure to include `{0}` in your template string to make sure there are no conflicts between accounts. Also, be aware that some vaults have restrictions on the characters allowed in a secret name.

## Using a Vault

### Enable Vault Key Storage

Ensure the appropriate environment variables are set based on the prerequisites listed above. Then specify the `UseAltPluginEncryption` switch with either `New-PAAccount` for new accounts or `Set-PAAccount` for existing accounts.

```powershell
# create a new account using vault key storage
New-PAAccount -AcceptTOS -Contact 'me@example.com' -UseAltPluginEncryption -Verbose

# migrate an existing account to use vault key storage
Set-PAAccount -UseAltPluginEncryption -Verbose
```

!!! warning
    If `UseAltPluginEncryption` was already enabled for an existing account, you will need to disable it before re-enabling it in order to use vault key storage.

The verbose output should indicate the name of the secret that was added to the vault specified by your environment variables. You should also be able to list all the secrets associated with Posh-ACME by running the following:

```powershell
# change the search string if you're using a custom template
Get-SecretInfo -Vault $env:POSHACME_VAULT_NAME -Name '*poshacme*'
```

If there was a problem accessing the vault, an warning is thrown and the module falls back to storing the key with the account object. You can verify the current configuration for an account by checking the `VaultGuid` and `sskey` properties on account objects like this:

```powershell
Get-PAAccount -List | Select-Object id,sskey,VaultGuid
```

When `sskey` is null or empty, the account is currently configured to use OS-native encryption. When `sskey` is set to `VAULT` and `VaultGuid` is not empty, the account is configured to use vault key storage. When `sskey` is any other value, the key is being stored with the account object.

### Disable Vault Key Storage

To disable vault key storage, use the standard process to disable alternative plugin encryption.

```powershell
Set-PAAccount -UseAltPluginEncryption:$false
```

If you still want to use alternative plugin encryption but without storing the key in a vault, remove your vault related environment variables and then re-enable alternative plugin encryption.

## Additional Considerations

### Losing the Vault Key

If the module is unable to retrieve the key from the vault, it will be unable to decrypt SecureString and PSCredential based plugin arguments and renewals will likely fail. If the key or vault was deleted or is otherwise no longer accessible, you will need to re-configure the plugin arguments for each order associated with the account using `Set-PAOrder`. 

If the vault access disruption is only temporary, the module will be able to continue processing renewals after access is restored. However, new orders or order modifications that configure new plugin arguments will reset the account's config with a new encryption key stored on the account object. It would be difficult to recover the existing plugin arguments on other orders without tedious manual intervention. So this should be avoided if possible.

### Rotating the Vault Key

If you believe the encryption key may have been compromised, you can rotate it by using the `ResetAltPluginEncryption` switch on `Set-PAAccount`.

```powershell
Set-PAAccount -ResetAltPluginEncryption
```

Using `ResetAltPluginEncryption` is also an easy way to migrate from storing the key on the account to storing it in a vault.

### Sharing Configs and Vaults

In some environments, the Posh-ACME config may be copied to multiple systems. Be wary when doing this using vault key storage. If the systems also share the same remote vault and you rotate the encryption key on one system, it will break the ability to decrypt plugin arguments on the other systems because the other systems won't have re-encrypted their copy of the plugin arguments with the new key. You will need to re-sync the config onto the other systems in order to fix it.
