---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/Functions/Set-PAOrder/
schema: 2.0.0
---

# Set-PAOrder

## Synopsis

Set the current ACME order, edits an orders properties, or revokes an order's certificate.

## Syntax

### Edit (Default)

```powershell
Set-PAOrder [[-MainDomain] <String>] [-Name <String>] [-NoSwitch] [-Plugin <String[]>]
 [-PluginArgs <Hashtable>] [-DnsAlias <String[]>] [-NewName <String>] [-FriendlyName <String>]
 [-PfxPass <String>] [-PfxPassSecure <SecureString>] [-Install] [-OCSPMustStaple] [-DnsSleep <Int32>]
 [-ValidationTimeout <Int32>] [-PreferredChain <String>] [-AlwaysNewKey] [-UseSerialValidation] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Revoke

```powershell
Set-PAOrder [[-MainDomain] <String>] [-Name <String>] [-RevokeCert] [-Force] [-NoSwitch] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## Description

Switch to a specific ACME order and edit its properties or revoke its certificate.
Revoked certificate orders are not deleted and can be re-requested using Submit-Renewal or New-PACertificate.

## Examples

### Example 1

```powershell
Set-PAOrder site1.example.com
```

Switch to the specified domain's order.

### Example 2

```powershell
Set-PAOrder -RevokeCert
```

Revoke the current order's certificate.

### Example 3

```powershell
Set-PAOrder -FriendlyName 'new friendly name'
```

Edit the friendly name for the current order and certificate if it exists.

## Parameters

### -MainDomain
The primary domain for the order.
For a SAN order, this was the first domain in the list when creating the order.

```yaml
Type: String
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RevokeCert
If specified, a request will be sent to the associated ACME server to revoke the certificate on this order.
Clients may wish to do this if the certificate is decommissioned or the private key has been compromised.
A warning will be displayed if the order is not currently valid or the existing certificate file can't be found.

```yaml
Type: SwitchParameter
Parameter Sets: Revoke
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
If specified, confirmation prompts for certificate revocation will be skipped.

```yaml
Type: SwitchParameter
Parameter Sets: Revoke
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoSwitch
If specified, the currently selected order will not change.
Useful primarily for bulk certificate revocation.
This switch is ignored if no MainDomain is specified.

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

### -Plugin
One or more validation plugin names to use for this order's challenges.
If no plugin is specified, the DNS "Manual" plugin will be used.
If the same plugin is used for all domains in the order, you can just specify it once.
Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the order.

```yaml
Type: String[]
Parameter Sets: Edit
Aliases: DnsPlugin

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginArgs
A hashtable containing the plugin arguments to use with the specified Plugin list.
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

```yaml
Type: Hashtable
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsAlias
One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone.
This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records.
If the same alias is used for all domains in the order, you can just specify it once.
Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

```yaml
Type: String[]
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewName
The new name for this ACME order.

```yaml
Type: String
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
The friendly name for the certificate and subsequent renewals.
This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported.
Must not be an empty string.

```yaml
Type: String
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PfxPass
The PFX password for the certificate and subsequent renewals.
When the PfxPassSecure parameter is specified, this parameter is ignored.

```yaml
Type: String
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PfxPassSecure
The PFX password for the certificate and subsequent renewals using a SecureString value.
When this parameter is specified, the PfxPass parameter is ignored.

```yaml
Type: SecureString
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Install
Enables the Install switch for the order.
Use -Install:$false to disable the switch on the order.
This affects whether the module will automatically import the certificate to the Windows certificate store on subsequent renewals.
It will not import the current certificate if it exists.
Use Install-PACertificate for that purpose.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OCSPMustStaple
If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsSleep
Number of seconds to wait for DNS changes to propagate before asking the ACME server to validate DNS challenges.

```yaml
Type: Int32
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidationTimeout
Number of seconds to wait for the ACME server to validate the challenges after asking it to do so.
If the timeout is exceeded, an error will be thrown.

```yaml
Type: Int32
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreferredChain
If the CA offers multiple certificate chains, prefer the chain with an issuer matching this Subject Common Name.
If no match, the default offered chain will be used.

```yaml
Type: String
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AlwaysNewKey
If specified, the order will be configured to always generate a new private key during each renewal.
Otherwise, the old key is re-used if it exists.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseSerialValidation
If specified, the names in the order will be validated individually rather than all at once.
This can significantly increase the time it takes to process validations and should only be used for plugins that require it.
The plugin's usage guide should indicate whether it is required.

```yaml
Type: SwitchParameter
Parameter Sets: Edit
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

## Related Links

[Get-PAOrder](Get-PAOrder.md)

[New-PAOrder](New-PAOrder.md)
