---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Submit-OrderFinalize

## SYNOPSIS
Finalize a certificate order

## SYNTAX

```
Submit-OrderFinalize [[-Order] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Finalizing a certificate order will send a new certificate request to the server and then wait for it to become valid or invalid.

## EXAMPLES

### EXAMPLE 1
```
Submit-OrderFinalize
```

Finalize the current order.

### EXAMPLE 2
```
Get-PAOrder example.com | Submit-OrderFinalize
```

Finalize the specified order.

## PARAMETERS

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PAOrder]()

[Submit-ChallengeValidation]()
