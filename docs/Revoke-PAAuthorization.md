---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Revoke-PAAuthorization

## SYNOPSIS
Revoke the authorization associated with an ACME identifier.

## SYNTAX

```
Revoke-PAAuthorization [-AuthURLs] <String[]> [[-Account] <Object>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Many ACME server implementations cache succesful authorizations for a certain amount of time to avoid requiring an account to re-authorize identifiers for additional orders submitted during the cache window.

This can make testing authorization challenges in a client more cumbersome by having to create new orders with uncached identifiers.
This function allows you to revoke those cached authorizations so that subsequent orders will go through the full challenge validation process.

## EXAMPLES

### EXAMPLE 1
```
Revoke-PAAuthorization https://acme.example.com/authz/1234567
```

Revoke the authorization for the specified URL using the current account.

### EXAMPLE 2
```
Get-PAOrder | Revoke-PAAuthorization -Force
```

Revoke all authorizations for the current order on the current account without confirmation prompts.

### EXAMPLE 3
```
Get-PAOrder -List | Revoke-PAAuthorizations
```

Revoke all authorizations for all orders on the current account.

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

### -Force
If specified, no confirmation prompts will be presented.

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

[Get-PAAuthorization]()

[Get-PAOrder]()
