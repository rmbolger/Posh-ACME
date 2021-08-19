---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://github.com/rmbolger/Posh-ACME
schema: 2.0.0
---

# Get-PAServer

## SYNOPSIS
Get ACME server details.

## SYNTAX

### Specific (Default)
```
Get-PAServer [[-DirectoryUrl] <String>] [-Name <String>] [-Refresh] [-Quiet] [<CommonParameters>]
```

### List
```
Get-PAServer [-List] [-Refresh] [<CommonParameters>]
```

## DESCRIPTION
The primary use for this function is checking which ACME server is currently configured.
New Account and Cert requests will be directed to this server.
It may also be used to refresh server details and list additional servers that have previously been used.

## EXAMPLES

### EXAMPLE 1
```
Get-PAServer
```

Get cached ACME server details for the currently selected server.

### EXAMPLE 2
```
Get-PAServer -DirectoryUrl LE_PROD
```

Get cached LetsEncrypt production server details using the short name.

### EXAMPLE 3
```
Get-PAServer -List
```

Get all cached ACME server details.

### EXAMPLE 4
```
Get-PAServer -DirectoryUrl https://myacme.example.com/directory
```

Get cached ACME server details for the specified directory URL.

### EXAMPLE 5
```
Get-PAServer -Refresh
```

Get fresh ACME server details for the currently selected server.

### EXAMPLE 6
```
Get-PAServer -List -Refresh
```

Get fresh ACME server details for all previously used servers.

## PARAMETERS

### -DirectoryUrl
Either the URL to an ACME server's "directory" endpoint or one of the supported short names.
Currently supported short names include LE_PROD (LetsEncrypt Production v2), LE_STAGE (LetsEncrypt Staging v2), BUYPASS_PROD (BuyPass.com Production), and BUYPASS_TEST (BuyPass.com Testing).

```yaml
Type: String
Parameter Sets: Specific
Aliases: location

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
The name of the ACME server.
The parameter is ignored if DirectoryUrl is specified.

```yaml
Type: String
Parameter Sets: Specific
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -List
If specified, the details for all previously used servers will be returned.

```yaml
Type: SwitchParameter
Parameter Sets: List
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Refresh
If specified, any server details returned will be freshly queried from the ACME server.
Otherwise, cached details will be returned.

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

### -Quiet
If specified, no warning will be thrown if a specified server is not found.

```yaml
Type: SwitchParameter
Parameter Sets: Specific
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

### PoshACME.PAServer
## NOTES

## RELATED LINKS

[https://github.com/rmbolger/Posh-ACME](https://github.com/rmbolger/Posh-ACME)

[Set-PAServer]()
