---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Set-PAServer/
schema: 2.0.0
---

# Set-PAServer

## Synopsis

Set the current ACME server and/or its configuration.

## Syntax

```powershell
Set-PAServer [[-DirectoryUrl] <String>] [-Name <String>] [-NewName <String>] [-SkipCertificateCheck]
 [-DisableTelemetry] [-NoRefresh] [-NoSwitch] [<CommonParameters>]
```

## Description

Use this function to set the current ACME server or change a server's configuration settings.

## Examples

### Example 1

```powershell
Set-PAServer LE_PROD
```

Switch to the LetsEncrypt production server using the short name.

### Example 2

```powershell
Set-PAServer -DirectoryUrl https://myacme.example.com/directory
```

Switch to the specified ACME server using the directory URL.

### Example 3

```powershell
(Get-PAServer -List)[0] | Set-PAServer
```

Switch to the first ACME server returned by "Get-PAServer -List"

## Parameters

### -DirectoryUrl
Either the URL to an ACME server's "directory" endpoint or one of the supported short names.
Currently supported short names include LE_PROD (LetsEncrypt Production v2), LE_STAGE (LetsEncrypt Staging v2), BUYPASS_PROD (BuyPass.com Production), and BUYPASS_TEST (BuyPass.com Testing).

```yaml
Type: String
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NewName
The new name of this ACME server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCertificateCheck
If specified, disable certificate validation while using this server.
This should not be necessary except in development environments where you are connecting to a self-hosted ACME server.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DisableTelemetry
If specified, telemetry data will not be sent to the Posh-ACME team for actions associated with this server.
The telemetry data that gets sent by default includes Posh-ACME version, PowerShell version, and generic OS platform (Windows/Linux/MacOS).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NoRefresh
If specified, the ACME server will not be re-queried for updated endpoints or a fresh nonce.

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

### -NoSwitch
If specified, the currently active ACME server will not be changed to the server being modified.

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

## Related Links

[Get-PAServer](Get-PAServer.md)
