---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Get-PAAuthorization

## SYNOPSIS
Get the authorizations associated with a particular order or set of authorization URLs.

## SYNTAX

```
Get-PAAuthorization [-AuthURLs] <String[]> [[-Account] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Returns details such as fqdn, status, expiration, and challenges for one or more ACME authorizations.

## EXAMPLES

### EXAMPLE 1
```
Get-PAAuthorization https://acme.example.com/authz/1234567
```

Get the authorization for the specified URL.

### EXAMPLE 2
```
Get-PAOrder | Get-PAAuthorization
```

Get the authorizations for the current order on the current account.

### EXAMPLE 3
```
Get-PAOrder -List | Get-PAAuthorization
```

Get the authorizations for all orders on the current account.

## PARAMETERS

### -AuthURLs
One or more authorization URLs.
You also pipe in one or more PoshACME.PAOrder objects.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: authorizations

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Account
An existing ACME account object such as the output from Get-PAAccount.
If no account is specified, the current account will be used.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PoshACME.PAAuthorization
## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PAOrder]()

[New-PAOrder]()
