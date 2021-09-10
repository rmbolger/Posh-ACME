---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Submit-OrderFinalize/
schema: 2.0.0
---

# Submit-OrderFinalize

## Synopsis

Finalize a certificate order

## Syntax

```powershell
Submit-OrderFinalize [[-Order] <Object>] [<CommonParameters>]
```

## Description

An ACME order that has reached the `ready` state is ready to be finalized which involves sending the certificate request to the ACME server so it can sign the certificate and transition the order into the `valid` state.

## Examples

### Example 1: Current Order

```powershell
Submit-OrderFinalize
```

Finalize the current order.

### Example 2: Specific Order

```powershell
Get-PAOrder example.com | Submit-OrderFinalize
```

Finalize the specified order.

## Parameters

### -Order
The ACME order to finalize.
The order object must be associated with the currently active ACME account.

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
An order object.

## Related Links

[Get-PAOrder](Get-PAOrder.md)

[Submit-ChallengeValidation](Submit-ChallengeValidation.md)
