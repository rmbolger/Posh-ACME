---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/Functions/Set-PAAccount/
schema: 2.0.0
---

# Set-PAAccount

## Synopsis

Set the current ACME account and/or update account details.

## Syntax

### Edit (Default)

```powershell
Set-PAAccount [[-ID] <String>] [[-Contact] <String[]>] [-NewName <String>] [-UseAltPluginEncryption]
 [-ResetAltPluginEncryption] [-Deactivate] [-Force] [-NoSwitch] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### RolloverImportKey

```powershell
Set-PAAccount [[-ID] <String>] [-KeyRollover] -KeyFile <String> [-NoSwitch] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Rollover

```powershell
Set-PAAccount [[-ID] <String>] [-KeyRollover] [-KeyLength <String>] [-NoSwitch] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## Description

This function allows you to switch between ACME accounts for a particular server.
It also allows you to update the contact information associated with an account, deactivate the account, or replace the account key with a new one.

## Examples

### Example 1

```powershell
Set-PAAccount -ID 1234567
```

Switch to the specified account.

### Example 2

```powershell
Set-PAAccount -Contact 'user1@example.com','user2@example.com'
```

Set new contacts for the current account.

### Example 3

```powershell
Set-PAAccount -ID 1234567 -Contact 'user1@example.com','user2@example.com'
```

Set new contacts for the specified account.

### Example 4

```powershell
Get-PAAccount -List | Set-PAAccount -Contact user1@example.com -NoSwitch
```

Set a new contact for all known accounts without switching from the current.

### Example 5

```powershell
Set-PAAccount -Deactivate
```

Deactivate the current account.

### Example 6

```powershell
Set-PAAccount -KeyRollover -KeyLength ec-384
```

Replace the current account key with a new ECC key using P-384 curve.

### Example 7

```powershell
Set-PAAccount -KeyRollover -KeyFile .\mykey.key
```

Replace the current account key with a pre-generated private key.

## Parameters

### -ID
The account id value as returned by the ACME server.
If not specified, the function will attempt to use the currently active account.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Contact
One or more email addresses to associate with this account.
These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

```yaml
Type: String[]
Parameter Sets: Edit
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewName
The new name (id) of this ACME account.

```yaml
Type: String
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAltPluginEncryption
If specified, the account will be configured to use a randomly generated AES key to encrypt sensitive plugin parameters on disk instead of using the OS's native encryption methods.
This can be useful if the config is being shared across systems or platforms.
You can revert to OS native encryption using -UseAltPluginEncryption:$false.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResetAltPluginEncryption
If specified, the existing AES key will be replaced with a new one and existing plugin parameters on disk will be re-encrypted with the new key.
If there is no existing key, this parameter is ignored.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Deactivate
If specified, a request will be sent to the associated ACME server to deactivate the account.
Clients may wish to do this if the account key is compromised or decommissioned.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, confirmation prompts for account deactivation will be skipped.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyRollover
If specified, generate a new account key and replace the current one with it.
Clients may choose to do this to recover from a key compromise or proactively mitigate the impact of an unnoticed key compromise.

```yaml
Type: SwitchParameter
Parameter Sets: RolloverImportKey, Rollover
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyLength
The type and size of private key to use.
For RSA keys, specify a number between 2048-4096 (divisible by 128).
For ECC keys, specify either 'ec-256' or 'ec-384'.
Defaults to 'ec-256'.

```yaml
Type: String
Parameter Sets: Rollover
Aliases: AccountKeyLength

Required: False
Position: Named
Default value: Ec-256
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyFile
The path to an existing EC or RSA private key file.
This will attempt to use the specified key as the new ACME account key.

```yaml
Type: String
Parameter Sets: RolloverImportKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoSwitch
If specified, the currently active account will not change.
Useful primarily for bulk updating contact information across accounts.
This switch is ignored if no ID is specified.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Get-PAAccount](Get-PAAccount.md)

[New-PAAccount](New-PAAccount.md)
