title: GoDaddyV3

# How To Use the GoDaddyV3 DNS Plugin

This plugin works against the [GoDaddy](https://www.godaddy.com) domain registrar hosted DNS provider on their V3 API version that authenticates using a Personal Access Token (PAT). It is assumed that you have already setup an account and registered a domain that is using the default Nameservers.

## Setup

Login to the [Personal Access Token](https://developer.godaddy.com/en/personal-access-token) page.

- Click `Generate Token`
- Name: **Posh-ACME** (or whatever you'd like)
- Expiration: 1 year (or whatever you'd like)
- Expand the Scopes list and select
  - `domains.domain:read`
  - `domains.dns:update` (not `domains.domain:update` which is different)
- Click `Generate Token` again
- Copy the generated token value somewhere safe. There's no way to retrieve it once you close the dialog box.

## Using the Plugin

The token value is used with the `GDPAT` SecureString parameter

```powershell
$pArgs = @{
    GDPAT = (Read-Host 'Enter Token' -AsSecureString)
}
New-PACertificate example.com -Plugin GoDaddyV3 -PluginArgs $pArgs
```
