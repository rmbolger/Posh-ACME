---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAOrder/
schema: 2.0.0
---

# Get-PAOrder

## Synopsis

Get ACME order details.

## Syntax

### Specific

```powershell
Get-PAOrder [[-MainDomain] <String>] [-Name <String>] [-Refresh] [<CommonParameters>]
```

### List

```powershell
Get-PAOrder [-List] [-Refresh] [<CommonParameters>]
```

## Description

Returns details such as Domains, key length, expiration, and status for one or more ACME orders previously created.

## Examples

### Example 1

```powershell
Get-PAOrder
```

Get cached ACME order details for the currently selected order.

### Example 2

```powershell
Get-PAOrder site.example.com
```

Get cached ACME order details for the specified domain.

### Example 3

```powershell
Get-PAOrder -List
```

Get all cached ACME order details.

### Example 4

```powershell
Get-PAOrder -Refresh
```

Get fresh ACME order details for the currently selected order.

### Example 5

```powershell
Get-PAOrder -List -Refresh
```

Get fresh ACME order details for all orders.

## Parameters

### -MainDomain
The primary domain associated with the order.
This is the domain that goes in the certificate's subject.

```yaml
Type: String
Parameter Sets: Specific
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
Parameter Sets: Specific
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -List
If specified, the details for all orders will be returned.

```yaml
Type: SwitchParameter
Parameter Sets: List
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Refresh
If specified, any order details returned will be freshly queried from the ACME server.
Otherwise, cached details will be returned.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PoshACME.PAOrder
An order object.

## Related Links

[Set-PAOrder](Set-PAOrder.md)

[New-PAOrder](New-PAOrder.md)
