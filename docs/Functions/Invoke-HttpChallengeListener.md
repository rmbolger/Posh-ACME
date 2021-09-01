---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Invoke-HttpChallengeListener/
schema: 2.0.0
---

# Invoke-HttpChallengeListener

## Synopsis

Starts a local web server to answer pending http-01 ACME challenges.

## Syntax

```powershell
Invoke-HttpChallengeListener [[-MainDomain] <String>] [[-Name] <String>] [-ListenerTimeout <Int32>]
 [-Port <Int32>] [-ListenerPrefixes <String[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

Uses System.Net.HttpListener to answer http-01 ACME challenges for the current or specified order.
If MainDomain is not specified, the current Order is used.

If running on Windows with non-admin privileges, Access Denied errors may be thrown unless a URL reservation is added using `netsh` that matches the HttpListener prefix that will be used. The default wildcard prefix is `http://+/.well-known/acme-challenge` and the netsh command might look something like this:

    netsh http add urlacl url=http://+/.well-known/acme-challenge/ user=Everyone

## Examples

### Example 1

```powershell
Invoke-HttpChallengeListener
```

Start listener on default port 80 for pending challenges for the current order.

### Example 2

```powershell
Invoke-HttpChallengeListener -MainDomain 'test.example.com' -Port 8080 -ListenerTimeout 30
```

Start listener on port 8080 with a timeout of 30 seconds for the specified order.

### Example 3

```powershell
$prefixes = 'http://example.com/.well-known/acme-challenge/','http://www.example.com/.well-known/acme-challenge'
Invoke-HttpChallengeListener -ListenerPrefixes $prefixes
```

Start listener using the specified prefixes for the current order.

## Parameters

### -MainDomain
The primary domain associated with an order.

```yaml
Type: String
Parameter Sets: (All)
Aliases: domain, fqdn

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
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ListenerTimeout
The timeout in seconds for the webserver.
When reached, the http listener stops regardless of challenge status.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: TTL

Required: False
Position: Named
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
The TCP port on which the http listener is listening.
80 by default.
This parameter is ignored when ListenerPrefixes is specified.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ListenerPrefixes
Overrides the default wildcard listener prefix with the specified prefixes instead.
Be sure to include the port if necessary and a trailing '/' on all included prefixes.
See https://docs.microsoft.com/en-us/dotnet/api/system.net.httplistener for details.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

## Outputs

### PoshACME.PAAuthorization
The authorization object associated with the order.

## Notes

> **DEPRECATION NOTICE:** This function is deprecated and may be removed in a future major version. Please migrate your scripts to use the `WebSelfHost` plugin.

## Related Links

[Get-PAOrder](Get-PAOrder.md)

[Get-PAAuthorization](Get-PAAuthorization.md)
