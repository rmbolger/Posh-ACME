---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Get-KeyAuthorization

## SYNOPSIS
Calculate a key authorization string for a challenge token.

## SYNTAX

```
Get-KeyAuthorization [-Token] <String> [[-Account] <Object>] [-ForDNS] [<CommonParameters>]
```

## DESCRIPTION
A key authorization is a string that expresses a domain holder's authorization for a specified key to satisfy a specified challenge, by concatenating the token for the challenge with a key fingerprint.

## EXAMPLES

### EXAMPLE 1
```
Get-KeyAuthorization 'XxXxXxXxXxXx'
```

Get the key authorization for the specified token using the current account.

### EXAMPLE 2
```
(Get-PAOrder | Get-PAAuthorization).DNS01Token | Get-KeyAuthorization
```

Get all key authorizations for the DNS challenges in the current order using the current account.

## PARAMETERS

### -Token
The token string for an ACME challenge.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Account
The ACME account associated with the challenge.

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

### -ForDNS
Enable this switch if you're using the key authorization value for the 'dns-01' challenge type.
It will do a few additional manipulation steps on the value that are required for a DNS TXT record.

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

### System.String
## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Get-PAAuthorization]()

[Submit-ChallengeValidation]()
