---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Submit-Renewal

## SYNOPSIS
Renew one or more certificates.

## SYNTAX

### Specific
```
Submit-Renewal [[-MainDomain] <String>] [[-Name] <String>] [-Force] [-NoSkipManualDns]
 [-PluginArgs <Hashtable>] [<CommonParameters>]
```

### AllOrders
```
Submit-Renewal [-AllOrders] [-Force] [-NoSkipManualDns] [-PluginArgs <Hashtable>] [<CommonParameters>]
```

### AllAccounts
```
Submit-Renewal [-AllAccounts] [-Force] [-NoSkipManualDns] [-PluginArgs <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
This function allows you to renew one more more previously completed certificate orders.
You can choose to renew a specific order or set of orders, all orders for the current account, or all orders for all accounts.

## EXAMPLES

### EXAMPLE 1
```
Submit-Renewal
```

Renew the current order on the current account.

### EXAMPLE 2
```
Submit-Renewal -Force
```

Renew the current order on the current account even if it hasn't reached its suggested renewal window.

### EXAMPLE 3
```
Submit-Renewal -AllOrders
```

Renew all valid orders on the current account that have reached their suggested renewal window.

### EXAMPLE 4
```
Submit-Renewal -AllAccounts
```

Renew all valid orders on all valid accounts that have reached their suggested renewal window.

### EXAMPLE 5
```
Submit-Renewal site1.example.com -Force
```

Renew the order for the specified site regardless of its renewal window.

## PARAMETERS

### -MainDomain
The primary domain associated with an order.
This is the domain that goes in the certificate's subject.

```yaml
Type: String
Parameter Sets: Specific
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
Parameter Sets: Specific
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AllOrders
If specified, renew all valid orders on the current account.
Orders that have not reached the renewal window will be skipped unless -Force is used.

```yaml
Type: SwitchParameter
Parameter Sets: AllOrders
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllAccounts
If specified, renew all valid orders on all valid accounts in this profile.
Orders that have not reached the renewal window will be skipped unless -Force is used.

```yaml
Type: SwitchParameter
Parameter Sets: AllAccounts
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, an order that hasn't reached its renewal window will not throw an error and will not be skipped when using either of the -All parameters.

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

### -NoSkipManualDns
If specified, orders that utilize the Manual DNS plugin will not be skipped and user interaction may be required to complete the process.
Otherwise, orders that utilize the Manual DNS plugin will be skipped.

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

### -PluginArgs
A hashtable containing an updated set of plugin arguments to use with the renewal.
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

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

[Get-PAOrder]()
