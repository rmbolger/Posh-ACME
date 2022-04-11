---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/New-PACertificate/
schema: 2.0.0
---

# New-PACertificate

## Synopsis

Request a new certificate

## Syntax

### FromScratch (Default)
```powershell
New-PACertificate [-Domain] <String[]> [-Name <String>] [-Contact <String[]>] [-CertKeyLength <String>]
 [-AlwaysNewKey] [-AcceptTOS] [-AccountKeyLength <String>] [-DirectoryUrl <String>] [-Plugin <String[]>]
 [-PluginArgs <Hashtable>] [-LifetimeDays <Int32>] [-DnsAlias <String[]>] [-OCSPMustStaple]
 [-FriendlyName <String>] [-PfxPass <String>] [-PfxPassSecure <SecureString>] [-Install] [-UseSerialValidation]
 [-Force] [-DnsSleep <Int32>] [-ValidationTimeout <Int32>] [-PreferredChain <String>] [<CommonParameters>]
```

### FromCSR
```powershell
New-PACertificate [-CSRPath] <String> [-Name <String>] [-Contact <String[]>] [-AcceptTOS]
 [-AccountKeyLength <String>] [-DirectoryUrl <String>] [-Plugin <String[]>] [-PluginArgs <Hashtable>]
 [-LifetimeDays <Int32>] [-DnsAlias <String[]>] [-UseSerialValidation] [-Force] [-DnsSleep <Int32>]
 [-ValidationTimeout <Int32>] [-PreferredChain <String>] [<CommonParameters>]
```

## Description
This is the primary function for this module and is capable executing the entire ACME certificate request process from start to finish without any prerequisite steps. However, utilizing the module's other functions can enable more complicated workflows and reduce the number of parameters you need to supply to this function.

## Examples

### Example 1: Basic Manual Certificate

```powershell
New-PACertificate 'example.com','www.example.com' -AcceptTOS
```

This is the bare minimum necessary to create a certificate for a basic domain (plus the `www` alt name). It prompts you to add the required DNS TXT record manually. You can omit the `-AcceptTOS` parameter if you already have an ACME account configured.

### Example 2: Wildcard Certificate with Contact

```powershell
New-PACertificate '*.example.com','example.com' -Contact 'admin@example.com'
```

Wildcard certificates generally include the non-wildcard root as a SAN because the wildcard doesn't match it. The contact email address is typically used by the CA to send expiration warnings.

### Example 3: Using a plugin

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
New-PACertificate 'example.com' -Plugin FakeDNS -PluginArgs $pArgs
```

Plugin parameters are passed as a basic hashtable object. Some parameters may require SecureString or PSCredential objects to protect sensitive API credentials, tokens, and keys.

### Example 4: Using multiple plugins

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
    WSHPort = 8080
}
New-PACertificate '*.example.com','example.com' -Plugin FakeDNS,WebSelfHost -PluginArgs $pArgs
```

Each name in a certificate can use a different plugin if necessary. Be sure the specified plugin order matches the order of the names they are associated with. If there are fewer plugins specified than names, the last plugin in the list will be applied to all remaining names.

Each plugin's parameters should be combined into the same hashtable object.

### Example 5: Using a DNS Challenge Alias

```powershell
$pArgs = @{
    FDToken = (Read-Host 'FakeDNS API Token' -AsSecureString)
}
New-PACertificate 'example.com' -Plugin FakeDNS -PluginArgs $pArgs -DnsAlias 'acme.example.net'
```

Using `DnsAlias` tells the plugin to create the required TXT record to an alternate hostname. It requires having added a CNAME record for each name in the cert pointing to the alternate record location. In this case, `_acme-challenge.example.com` is pointing to `acme.example.net`.

## Parameters

### -Domain

One or more domain names to include in this order/certificate.
The first one in the list will be considered the "MainDomain" and be set as the subject of the finalized certificate.

```yaml
Type: String[]
Parameter Sets: FromScratch
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CSRPath

The path to a pre-made certificate request file in PEM (Base64) format.
This is useful for appliances that need to generate their own keys and cert requests.

```yaml
Type: String
Parameter Sets: FromCSR
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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
Accept pipeline input: False
Accept wildcard characters: False
```

### -Contact

One or more email addresses to associate with this certificate.
These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

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

### -CertKeyLength

The type and size of private key to use for the certificate.
For RSA keys, specify a number between 2048-4096 (divisible by 128).
For ECC keys, specify either 'ec-256' or 'ec-384'.
Defaults to '2048'.

```yaml
Type: String
Parameter Sets: FromScratch
Aliases:

Required: False
Position: Named
Default value: 2048
Accept pipeline input: False
Accept wildcard characters: False
```

### -AlwaysNewKey

If specified, the order will be configured to always generate a new private key during each renewal.
Otherwise, the old key is re-used if it exists.

```yaml
Type: SwitchParameter
Parameter Sets: FromScratch
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AcceptTOS

This switch is required when creating a new account as part of a certificate request.
It implies you have read and accepted the Terms of Service for the ACME server you are connected to.
The first time you connect to an ACME server, a link to the Terms of Service should have been displayed.

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

### -AccountKeyLength

The type and size of private key to use for the account associated with this certificate.
For RSA keys, specify a number between 2048-4096 (divisible by 128).
For ECC keys, specify either 'ec-256' or 'ec-384'.
Defaults to 'ec-256'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Ec-256
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryUrl
Either the URL to an ACME server's "directory" endpoint or one of the supported short names. Currently supported short names include LE_PROD (LetsEncrypt Production), LE_STAGE (LetsEncrypt Staging), BUYPASS_PROD (BuyPass.com Production), BUYPASS_TEST (BuyPass.com Testing), and ZEROSSL_PROD (Zerossl.com Production).

```yaml
Type: String
Parameter Sets: (All)
Aliases: location

Required: False
Position: Named
Default value: LE_PROD
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
Aliases: DnsPlugin

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
Parameter Sets: FromScratch
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName

Set a friendly name for the certificate.
This will populate the "Friendly Name" field in the Windows certificate store when the PFX is imported.
Defaults to the first item in the Domain parameter.

```yaml
Type: String
Parameter Sets: FromScratch
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
Parameter Sets: FromScratch
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
Parameter Sets: FromScratch
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Install

If specified, the certificate generated for this order will be imported to the local computer's Personal certificate store.
Using this switch requires running the command from an elevated PowerShell session.

```yaml
Type: SwitchParameter
Parameter Sets: FromScratch
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

### -Force

If specified, a new certificate order will always be created regardless of the status of a previous order for the same primary domain.
Otherwise, the previous order still in progress will be used instead.

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
Default is 120.

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
Default is 60.
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PoshACME.PACertificate
A certificate object.

## Related Links

[Submit-Renewal](Submit-Renewal.md)

[Get-PAPlugin](Get-PAPlugin.md)
