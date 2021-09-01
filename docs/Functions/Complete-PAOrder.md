---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Complete-PAOrder/
schema: 2.0.0
---

# Complete-PAOrder

## Synopsis

Exports cert files for a completed order and adds suggested renewal window to the order.

## Syntax

```powershell
Complete-PAOrder [[-Order] <PoshACME.PAOrder>] [<CommonParameters>]
```

## Description

Once an ACME order is finalized, the signed certificate and chain can be downloaded and combined with the local private key to generate the supported PEM and PFX files on disk.
This function will also calculate the renewal window based on the signed certificate's expiration date and update the order object with that info.
If the Install flag is set, this function will attempt to import the certificate into the Windows certificate store.

## Examples

### Example 1: Complete the current order

```powershell
Complete-PAOrder
```

### Example 2: Complete a specific order

```powershell
Get-PAOrder example.com | Complete-PAOrder
```

## Parameters

### -Order
The order object to complete which must be associated with the currently active ACME account.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

### PoshACME.PAOrder
An order object as returned by Get-PAOrder.

## Outputs

### PoshACME.PACertificate
The certificate object for the order.

## Related Links

[Get-PAOrder](Get-PAOrder.md)

[New-PAOrder](New-PAOrder.md)
