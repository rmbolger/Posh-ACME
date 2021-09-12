---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Remove-PAServer/
schema: 2.0.0
---

# Remove-PAServer

## Synopsis

Remove an ACME server and all associated accounts, orders, and certificates from the local profile.

## Syntax

```powershell
Remove-PAServer [[-DirectoryUrl] <String>] [-Name <String>] [-DeactivateAccounts] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## Description

This function removes the ACME server from the local profile which also removes any associated accounts, orders and certificates. It will not remove or cleanup copies of certificates that have been exported or installed elsewhere.
It will not revoke any certificates. It will not deactivate the accounts on the ACME server unless the `-DeactivateAccounts` switch is specified.

## Examples

### Example 1: Remove Server

```powershell
Remove-PAServer LE_STAGE
```

Remove the specified server without deactivating accounts.

### Example 2: Remove and Deactivate Accounts

```powershell
Get-PAServer | Remove-PAServer -DeactivateAccounts -Force
```

Remove the current server and deactivates accounts without confirmation.

## Parameters

### -DirectoryUrl
Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production), LE_STAGE (LetsEncrypt Staging), BUYPASS_PROD (BuyPass.com Production), BUYPASS_TEST (BuyPass.com Testing), and ZEROSSL_PROD (Zerossl.com Production).

```yaml
Type: String
Parameter Sets: (All)
Aliases: location

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
The name of the ACME server.
The parameter is ignored if DirectoryUrl is specified.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DeactivateAccounts
If specified, an attempt will be made to deactivate the accounts in this profile before deletion.
Clients may wish to do this if the account key is compromised or being decommissioned.

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

[Get-PAServer](Get-PAServer.md)

[Set-PAServer](Set-PAServer.md)
