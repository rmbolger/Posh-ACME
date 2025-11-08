---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PAServer/
schema: 2.0.0
---

# Get-PAServer

## Synopsis

Get ACME server details.

## Syntax

### Specific (Default)
```powershell
Get-PAServer [[-DirectoryUrl] <String>] [-Name <String>] [-Refresh] [-Quiet] [<CommonParameters>]
```

### List
```powershell
Get-PAServer [-List] [-Refresh] [<CommonParameters>]
```

## Description

The primary use for this function is checking which ACME server is currently configured.
New Account and Cert requests will be directed to this server.
It may also be used to refresh server details and list additional servers that have previously been used.

## Examples

### Example 1: Current Server

```powershell
Get-PAServer
```

Get cached ACME server details for the currently selected server.

### Example 2: Specific Server

```powershell
Get-PAServer -DirectoryUrl LE_PROD
```

Get cached LetsEncrypt production server details using the short name.

### Example 3: Specific Server URL

```powershell
Get-PAServer -DirectoryUrl https://myacme.example.com/directory
```

Get cached ACME server details for the specified directory URL.

### Example 4: All Servers

```powershell
Get-PAServer -List
```

Get all cached ACME server details.

## Parameters

### -DirectoryUrl
Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD and LE_STAGE (LetsEncrypt), ZEROSSL_PROD (Zerossl.com), GOOGLE_PROD and GOOGLE_STAGE (pki.goog), SSLCOM_RSA and SSLCOM_ECC (ssl.com), and ACTALIS_PROD (Actalis.com).

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

## Outputs

### PoshACME.PAServer
A server object.

## Related Links

[Set-PAServer](Set-PAServer.md)
