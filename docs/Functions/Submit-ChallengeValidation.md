---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/Functions/Submit-ChallengeValidation/
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

An ACME order contains an authorization object for each domain in the order. Each authorization contains one or more challenge types. The client must complete at least one challenge for each authorization in order to prove they control the domain. Once complete, the client asks the server to validate each challenge and waits for the server to do so and update the authorization status.

## Examples

### Example 1

```powershell
Submit-ChallengeValidation
```

Begin challenge validation on the current order.

### Example 2

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

[Get-PAOrder](Get-PAOrder.md)

[New-PAOrder](New-PAOrder.md)
