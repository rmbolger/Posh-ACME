---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Remove-PAOrder/
schema: 2.0.0
---

# Remove-PAOrder

## Synopsis

Remove an ACME order from the local profile.

## Syntax

```powershell
Remove-PAOrder [[-MainDomain] <String>] [[-Name] <String>] [-RevokeCert] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## Description

This function removes the order from the local profile which also removes any associated certificate/key.
It will not remove or cleanup copies of the certificate that have been exported or installed elsewhere.
It will not revoke the certificate unless `-RevokeCert` is specified.
The ACME server may retain a reference to the order until it decides to delete it.

## Examples

### Example 1

```powershell
Remove-PAOrder site1.example.com
```

Remove the specified order without revoking the certificate.

### Example 2

```powershell
Get-PAOrder -List | Remove-PAOrder -RevokeCert -Force
```

Remove all orders associated with the current account, revoke all certificates, and skip confirmation prompts.

## Parameters

### -MainDomain
The primary domain for the order.
For a SAN order, this was the first domain in the list when creating the order.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
The name of the ACME order.
This can be useful to distinguish between two orders that have the same MainDomain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RevokeCert
If specified and there is a currently valid certificate associated with the order, the certificate will be revoked before deleting the order.
This is not required, but generally a good practice if the certificate is no longer being used.

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

[Get-PAOrder](Get-PAOrder.md)

[New-PAOrder](New-PAOrder.md)
