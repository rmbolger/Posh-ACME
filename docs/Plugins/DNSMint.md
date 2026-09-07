title: DNSMint

# How To Use the DNSMint DNS Plugin

This plugin works against [DNSMint](https://dnsmint.com/), which hands out hostnames on domains it operates rather than hosting zones you own. DNSMint therefore knows which hostname a challenge belongs to from the record name alone, so the plugin has no zone to look up and no record ID to keep track of.

## Setup

- Sign in at [dnsmint.com](https://dnsmint.com/) and mint a hostname.
- From the dashboard, create an API key with the `dns01:write` scope, narrowed to that hostname. A key at that scope can publish `_acme-challenge` TXT records for the one name and nothing else.
- Copy the key. It is shown once.

## Using the Plugin

The API key is passed as a SecureString in the `DNSMintToken` parameter.

```powershell
$pArgs = @{
    DNSMintToken = (Read-Host 'DNSMint API Key' -AsSecureString)
}
New-PACertificate 'q7k4m2.dnsmint-a3f9c1.dev' -Plugin DNSMint -PluginArgs $pArgs
```

A wildcard needs the same key. Name the plugin once per certificate name so the module does not have to guess.

```powershell
New-PACertificate 'q7k4m2.dnsmint-a3f9c1.dev','*.q7k4m2.dnsmint-a3f9c1.dev' -Plugin DNSMint,DNSMint -PluginArgs $pArgs
```

A hostname that resolves to a public address and does not need a wildcard can use `http-01` instead and needs no plugin at all.
