---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Remove-PAAccount/
schema: 2.0.0
---

# Remove-PAAccount

## Synopsis

Remove an ACME account and all associated orders and certificates from the local profile.

## Syntax

```powershell
Remove-PAAccount [-ID] <String> [-Deactivate] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

This function removes the ACME account from the local profile which also removes any associated orders and certificates. It will not remove or cleanup copies of certificates that have been exported or installed elsewhere. It will not deactivate the account on the ACME server unless `-Deactivate` is specified. But you won't be able to re-use the account on another system without an export of the account's key such as the one generated with `Export-PAAccountKey`.

## Examples

### Example 1: Remove Account

```powershell
Remove-PAAccount 12345
```

Remove the specified account without deactivation.

### Example 2: Deactivate and Remove

```powershell
Get-PAAccount | Remove-PAAccount -Deactivate -Force
```

Remove the current account after deactivating it and skip confirmation prompts.

## Parameters

### -ID
The account id value as returned by the ACME server.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Deactivate
If specified, a request will be sent to the associated ACME server to deactivate the account.
Clients may wish to do this if the account key is compromised or decommissioned.

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

### -Force
If specified, interactive confirmation prompts will be skipped.

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
