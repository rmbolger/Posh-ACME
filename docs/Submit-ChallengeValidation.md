---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Submit-ChallengeValidation

## SYNOPSIS
Respond to authorization challenges for an ACME order and wait for the ACME server to validate them.

## SYNTAX

```
Submit-ChallengeValidation [[-Order] <Object>] [<CommonParameters>]
```

## DESCRIPTION
An ACME order contains an authorization object for each domain in the order.
The client must complete at least one of a set of challenges for each authorization in order to prove they own the domain.
Once complete, the client asks the server to validate each challenge and waits for the server to do so and update the authorization status.

## EXAMPLES

### EXAMPLE 1
```
Submit-ChallengeValidation
```

Begin challenge validation on the current order.

### EXAMPLE 2
```
Get-PAOrder | Submit-ChallengeValidation
```

Begin challenge validation on the current order.

## PARAMETERS

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PAOrder]()

[New-PAOrder]()
