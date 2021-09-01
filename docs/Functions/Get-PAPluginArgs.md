---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAPluginArgs/
schema: 2.0.0
---

# Get-PAPluginArgs

## Synopsis

Retrieve the plugin args for the current or specified order.

## Syntax

```powershell
Get-PAPluginArgs [[-MainDomain] <String>] [-Name <String>] [<CommonParameters>]
```

## Description

An easy way to recall the plugin args used for a given order.

## Examples

### Example 1

```powershell
Get-PAPluginArgs
```

Retrieve the plugin args for the current order.

### Example 2

```powershell
Get-PAPluginArgs -Name myorder
```

Retrieve the plugin args for the specified order.

### Example 3

```powershell
Get-PAOrder -Name myorder | Get-PAPluginArgs
```

Retrieve the plugin args for the order passed via the pipeline.

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
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### System.Collections.Hashtable
A hashtable containing saved plugin parameters.

## Related Links

[Gew-PAOrder](Get-PAOrder.md)
