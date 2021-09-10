---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Submit-ChallengeValidation/
schema: 2.0.0
---

# Submit-ChallengeValidation

## Synopsis

Respond to authorization challenges for an ACME order and wait for the ACME server to validate them.

## Syntax

```powershell
Submit-ChallengeValidation [[-Order] <Object>] [<CommonParameters>]
```

## Description

This function encapsulates the authorization validation cycle for challenges in a given order. It takes care of publishing the challenge records according to the order's plugin configuration, notifying the ACME server to validate the records, and cleaning up the challenge records whether the validation succeeded or not.

If everything is successful, the order object will have transitioned from the `pending` state to the `ready` state which indicates it is ready for finalization using `Submit-OrderFinalize`.

## Examples

### Example 1: Current Order

```powershell
Submit-ChallengeValidation
```

Begin challenge validation on the current order.

### Example 2: Specific Order

```powershell
Get-PAOrder -Name myorder | Submit-ChallengeValidation
```

Begin challenge validation on the specified order.

## Parameters

### -Order
The ACME order to perform the validations against.
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

[New-PAOrder](New-PAOrder.md)

[Submit-OrderFinalize](Submit-OrderFinalize.md)
