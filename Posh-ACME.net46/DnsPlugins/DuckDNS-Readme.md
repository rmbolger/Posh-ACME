# How To Use the DuckDNS Plugin

This plugin works against the [Duck DNS](https://www.duckdns.org/) provider. It is assumed that you have already setup an account and created the domain(s) you will be working against.

## Setup

Look for a `token` value listed on the Duck DNS homepage after you login. You'll need to supply this value as one of the plugin parameters. You will also need your domain subname.

## Using the Plugin

Duck DNS has a rather annoying limitation that there can only ever be a single TXT record associated with all domains on your account. Because of the way Posh-ACME works, this means you can only use `New-PACertificate` normally if your certificate will only have a single name in it.

Your API token is specified using `DuckToken` or `DuckTokenInsecure` parameter. `DuckToken` is a SecureString value and should only be used from Windows or any OS with PowerShell 6.2 or later. `DuckTokenInsecure` may be used with any OS.

You also need to specify the domain or list of domains associated with your account using the `DuckDomain` parameter. You need to include all of the domains on your account in this parameter if you plan on getting additional certificates for the other domains.

### Windows and/or PS 6.2+ only (secure string)
```powershell
$secToken = Read-Host -Prompt "Token" -AsSecureString
$pArgs = @{
    DuckToken = $secToken
    DuckDomain = 'mydomain1','mydomain2'
}
New-PACertificate mydomain1.duckdns.org -DnsPlugin DuckDNS -PluginArgs $pArgs
```

### Any OS (default string)
```powershell
$pArgs = @{
    DuckTokenInsecure = 'token-value'
    DuckDomain = 'mydomain1','mydomain2'
}
New-PACertificate mydomain1.duckdns.org -DnsPlugin DuckDNS -PluginArgs $pArgs
```

## (Advanced) Using the Plugin with Multiple Names

Because DuckDNS doesn't support creating multiple different TXT records at the same time, getting a certificate that contains multiple names such as `mydomain.duckdns.org` and `www.mydomain.duckdns.org` requires using a custom script to get around that limitation. It is also required for renewals.

Here is an example of how a custom script for this might work.

```powershell
# Assume we already have the $pArgs defined from the previous examples
# and an existing ACME account already setup

# Create the new order
$domains = 'mydomain1.duckdns.org','www.mydomain1.duckdns.org'
New-PAOrder $domains

# Get the pending authorizations
$auths = Get-PAOrder | Get-PAAuthorization | ?{ $_.status -eq 'pending' }

# Publish and Validate each authorization before moving onto the next
$auths | %{
    Write-Verbose "Publishing for $($_.DNSId)"
    Publish-DNSChallenge $_.DNSId (Get-PAAccount) $_.DNS01Token DuckDNS $pArgs

    Write-Verbose "Sleeping for DNS propagation"
    Start-Sleep 30
    
    Write-Verbose "Validating the challenge for $($_.DNSId)"
    $_.DNS01Url | Send-ChallengeAck
}

# Complete the order if the challenges were all validated successfully
if ('ready' -eq (Get-PAOrder -Refresh).status) {
    New-PACertificate $domains
} else {
    # Something didn't work. Add your own error response logic.
    # Here's how to get the list of challenges that failed.
    $badChallenges = Get-PAOrder | Get-PAAuthorization |
        Select -Expand challenges | ?{ $_.status -ne 'valid' }
}
```
