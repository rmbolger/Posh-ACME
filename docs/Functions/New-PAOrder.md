---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/New-PAOrder/
schema: 2.0.0
---

# New-PAOrder

## Synopsis

Create a new order on the current ACME account.

## Syntax

### FromScratch (Default)
```powershell
New-PAOrder [-Domain] <String[]> [[-KeyLength] <String>] [-Name <String>] [-Plugin <String[]>]
 [-PluginArgs <Hashtable>] [-LifetimeDays <Int32>] [-DnsAlias <String[]>] [-OCSPMustStaple] [-AlwaysNewKey]
 [-Subject <String>] [-FriendlyName <String>] [-PfxPass <String>] [-PfxPassSecure <SecureString>]
 [-UseModernPfxEncryption] [-Install] [-UseSerialValidation] [-DnsSleep <Int32>] [-ValidationTimeout <Int32>]
 [-PreferredChain <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ImportKey
```powershell
New-PAOrder [-Domain] <String[]> -KeyFile <String> [-Name <String>] [-Plugin <String[]>]
 [-PluginArgs <Hashtable>] [-LifetimeDays <Int32>] [-DnsAlias <String[]>] [-OCSPMustStaple] [-AlwaysNewKey]
 [-Subject <String>] [-FriendlyName <String>] [-PfxPass <String>] [-PfxPassSecure <SecureString>]
 [-UseModernPfxEncryption] [-Install] [-UseSerialValidation] [-DnsSleep <Int32>] [-ValidationTimeout <Int32>]
 [-PreferredChain <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### FromCSR
```powershell
New-PAOrder [-CSRPath] <String> [-Name <String>] [-Plugin <String[]>] [-PluginArgs <Hashtable>]
 [-LifetimeDays <Int32>] [-DnsAlias <String[]>] [-UseSerialValidation] [-DnsSleep <Int32>]
 [-ValidationTimeout <Int32>] [-PreferredChain <String>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

Creating an ACME order is the first step of the certificate request process.
To create a SAN certificate with multiple names, include them all in an array for the -Domain parameter.
The first name in the list will be considered the "MainDomain" and will also be in the certificate subject field.
Different CAs have different policies regarding the number of SANs a certificate may have.

Be aware that new orders that share the same MainDomain as a previous order will overwrite the previous order unless the `Name` paraemter is specified and there are no other order matches for that name.

## Examples

### Example 1: Single Domain Order

```powershell
New-PAOrder example.com
```

Create a new order for the specified domain using the default key length.

### Example 2: Multi-Domain with Plugin

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
$domains = 'example.com','www.example.com','blog.example.com'
New-PAOrder -Domain $domains -Plugin FakeDNS -PluginArgs $pArgs
```

Create a new SAN order for the specified domains and specify plugin details.

### Example 3: ECDSA Private Key

```powershell
New-PAOrder example.com -KeyLength 'ec-256'
```

Create a new order for the specified domain using an ECDSA P-256 private key.

### Example 4: Pre-generated Private Key

```powershell
New-PAOrder example.com -KeyFile .\mykey.key
```

Create a new order using an externally generated private key.

### Example 5: External Cert Request

```powershell
New-PAOrder -CSRPath .\myreq.csr
```

Create a new order using an externally generated certificate request.

## Parameters

### -Domain
One or more domain names to include in this order/certificate.
The first one in the list will be considered the "MainDomain" and be set as the subject of the finalized certificate.

```yaml
Type: String[]
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CSRPath
Either the filesystem path to a certificate request (CSR) file in PEM (Base64) format or the raw string contents of such a file. If using the string version, the PEM header and footer must be separated by line breaks from the Base64 content just like they would be in a normal file. This is useful for appliances that need to generate their own keys and cert requests or when the private key is otherwise unavailable.

```yaml
Type: String
Parameter Sets: FromCSR
Aliases: CSRString

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyLength
The type and size of private key to use.
For RSA keys, specify a number between 2048-4096 (divisible by 128).
For ECC keys, specify either 'ec-256' or 'ec-384'.
Defaults to '2048'.

```yaml
Type: String
Parameter Sets: FromScratch
Aliases:

Required: False
Position: 2
Default value: 2048
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyFile
The path to an existing EC or RSA private key file.
This will attempt to create the order using the specified key as the certificate's private key.

```yaml
Type: String
Parameter Sets: ImportKey
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the ACME order.
This can be useful to distinguish between two orders that have the same MainDomain.
If not specified, defaults to the first domain in the order.

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

### -Plugin
One or more validation plugin names to use for this order's challenges.
If no plugin is specified, the DNS "Manual" plugin will be used.
If the same plugin is used for all domains in the order, you can just specify it once.
Otherwise, you should specify as many plugin names as there are domains in the order and in the same sequence as the order.

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

### -PluginArgs
A hashtable containing the plugin arguments to use with the specified Plugin list.
So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as `@{MyText='text';MyNumber=1234}`.

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

### -DnsAlias
One or more FQDNs that DNS challenges should be published to instead of the certificate domain's zone.
This is used in advanced setups where a CNAME in the certificate domain's zone has been pre-created to point to the alias's FQDN which makes the ACME server check the alias domain when validation challenge TXT records.
If the same alias is used for all domains in the order, you can just specify it once.
Otherwise, you should specify as many alias FQDNs as there are domains in the order and in the same sequence as the order.

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

### -OCSPMustStaple
If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

```yaml
Type: SwitchParameter
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AlwaysNewKey
If specified, the order will be configured to always generate a new private key during each renewal.
Otherwise, the old key is re-used if it exists.

```yaml
Type: SwitchParameter
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
Sets the x509 "Subject" field in the certificate request that gets sent to the ACME server. By default, it is set to 'CN=FQDN' where 'FQDN' is the first name in the Domain parameter. For public certificate authorities issuing DV certificates, anything other than a DNS name from the list of domains will either be rejected or stripped from the finalized certificate.

```yaml
Type: String
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
Set a friendly name for the certificate.
This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported.
Defaults to the first item in the Domain parameter.

```yaml
Type: String
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PfxPass
Set the export password for generated PFX files.
Defaults to 'poshacme'.
When the PfxPassSecure parameter is specified, this parameter is ignored.

```yaml
Type: String
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: Poshacme
Accept pipeline input: False
Accept wildcard characters: False
```

### -PfxPassSecure
Set the export password for generated PFX files using a SecureString value.
When this parameter is specified, the PfxPass parameter is ignored.

```yaml
Type: SecureString
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Install
If specified, the certificate generated for this order will be imported to the local computer's Personal certificate store.

```yaml
Type: SwitchParameter
Parameter Sets: FromScratch, ImportKey
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
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 120
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidationTimeout
Number of seconds to wait for the ACME server to validate the challenges after asking it to do so.
If the timeout is exceeded, an error will be thrown.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreferredChain
If the CA offers multiple certificate chains, prefer the chain with an issuer matching this Subject Common Name.
If no match, the default offered chain will be used.

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

### -Force
If specified, confirmation prompts that may have been generated will be skipped.

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

### -LifetimeDays

How long in days the certificate should be valid for. NOTE: Many CAs do not support this feature and have fixed lifetime values. Some may ignore the request. Others may throw an error if specified.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseModernPfxEncryption

If specified, PFX files generated from this order will use AES256 with SHA256 for the private key encryption instead of the default which is RC2-40-CBC. This can affect compatibility with some crypto libraries and tools. Most notably, OpenSSL 3.x requires the newer options to avoid using "legacy" mode. But it breaks compatibility with OpenSSL 1.0.x.

```yaml
Type: SwitchParameter
Parameter Sets: FromScratch, ImportKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PoshACME.PAOrder
An order object.

## Related Links

[Get-PAOrder](Get-PAOrder.md)

[Set-PAOrder](Set-PAOrder.md)
