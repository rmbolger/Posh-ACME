---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Revoke-PACertificate

## SYNOPSIS
Revoke an ACME certificate

## SYNTAX

### MainDomain (Default)
```
Revoke-PACertificate [[-MainDomain] <String>] [-Name <String>] [-Reason <RevocationReasons>] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### CertFile
```
Revoke-PACertificate -CertFile <String> [-KeyFile <String>] [-Reason <RevocationReasons>] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Revokes a previously created ACME certificate.

## EXAMPLES

### EXAMPLE 1
```
Revoke-PACertificate example.com
```

Revokes the certificate for the specified domain.

### EXAMPLE 2
```
Get-PAOrder | Revoke-PACertificate -Force
```

Revokes the certificate associated with the current order and skips the confirmation prompt.

### EXAMPLE 3
```
Get-PACertificate | Revoke-PACertificate -Reason keyCompromise
```

Revokes the current certificate with the specified reason.

### EXAMPLE 4
```
Revoke-PACertificate -CertFile mycert.crt -KeyFile mycert.key
```

Revokes the specified cert using the specified private key.

## PARAMETERS

### -MainDomain
The primary domain associated with the certificate to be revoked.

```yaml
Type: String
Parameter Sets: MainDomain
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
Parameter Sets: MainDomain
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CertFile
A PEM-encoded certificate file to be revoked.

```yaml
Type: String
Parameter Sets: CertFile
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -KeyFile
The PEM-encoded private key associated with CertFile.
If not specified, the current ACME account will be used to sign the request.

```yaml
Type: String
Parameter Sets: CertFile
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Reason
The reason for cert revocation.
This must be one of the reasons defined in RFC 5280 including keyCompromise, cACompromise, affiliationChanged, superseded, cessationOfOperation, certificateHold, removeFromCRL, privilegeWithdrawn, and aACompromise.
NOTE: Not all reason codes are supported by all ACME certificate authorities.

```yaml
Type: RevocationReasons
Parameter Sets: (All)
Aliases:
Accepted values: keyCompromise, cACompromise, affiliationChanged, superseded, cessationOfOperation, certificateHold, removeFromCRL, privilegeWithdrawn, aACompromise

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, the revocation confirmation prompt will be skipped.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[New-PACertificate]()
