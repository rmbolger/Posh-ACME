---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Get-PAOrder

## SYNOPSIS
Get ACME order details.

## SYNTAX

### Specific
```
Get-PAOrder [[-MainDomain] <String>] [-Name <String>] [-Refresh] [<CommonParameters>]
```

### List
```
Get-PAOrder [-List] [-Refresh] [<CommonParameters>]
```

## DESCRIPTION
Returns details such as Domains, key length, expiration, and status for one or more ACME orders previously created.

## EXAMPLES

### EXAMPLE 1
```
Get-PAOrder
```

Get cached ACME order details for the currently selected order.

### EXAMPLE 2
```
Get-PAOrder site.example.com
```

Get cached ACME order details for the specified domain.

### EXAMPLE 3
```
Get-PAOrder -List
```

Get all cached ACME order details.

### EXAMPLE 4
```
Get-PAOrder -Refresh
```

Get fresh ACME order details for the currently selected order.

### EXAMPLE 5
```
Get-PAOrder -List -Refresh
```

Get fresh ACME order details for all orders.

## PARAMETERS

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

## INPUTS

## OUTPUTS

### PoshACME.PAOrder
## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Set-PAOrder]()

[New-PAOrder]()
