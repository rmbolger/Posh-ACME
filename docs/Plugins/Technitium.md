# How To Use the Technitium DNS Plugin

This plugin works against the [Technitium DNS Server](https://technitium.com/dns/). It is assumed that you have already installed Technitium DNS Server and created the DNS zone(s) you will be working against.

## Setup

### API Token

**Security Best Practice:** Create a dedicated user account with limited permissions rather than using the admin user's API token. See the [Security Considerations](#security-considerations) section below for detailed guidance.

#### Quick Setup Steps:

1. Login to your Technitium DNS Server web console as admin
2. Navigate to **Administration** > **Users** and create a new user (e.g., "acme-user")
3. Navigate to **Zones** and grant the new user **View** and **Modify** access to only the zones that need certificates
4. Logout and login as the new user
5. Click the top right user menu and select **Create API Token**
6. Enter the user's password, provide a token name (e.g., "posh-acme"), and click **Create**
7. Copy the token immediately - it will only be displayed once
8. Store the token securely - you'll need it for plugin configuration

### Network Access

Ensure that your system running Posh-ACME can reach the Technitium DNS Server's API endpoint:
- **HTTPS (recommended)**: Port **53443** (default)
- **HTTP (testing only)**: Port **5380** (default)
- If using a firewall, ensure the appropriate port is accessible

**Clustering Note (v14+):** If you're using Technitium's clustering feature, the `TechnitiumServer` parameter must point to your **primary (writable) node**. Secondary nodes in the cluster are read-only and cannot accept DNS record modifications.

## Using the Plugin

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| TechnitiumToken | SecureString | Yes | The API token for your Technitium DNS Server |
| TechnitiumServer | String | Yes | The hostname/IP and port of your Technitium server (e.g., 'dns.example.com:5380' or '192.168.1.100:5380') |
| TechnitiumProtocol | String | No | Protocol to use: 'https' (default) or 'http'. HTTPS is strongly recommended for production use |
| TechnitiumTTL | Integer | No | The TTL in seconds for the TXT records (default: 3600) |

### Example: Basic Certificate Request

```powershell
# Read the API token securely
$token = Read-Host -Prompt "Enter Technitium API Token" -AsSecureString

# Create the plugin arguments hashtable
$pArgs = @{
    TechnitiumToken = $token
    TechnitiumServer = 'dns.example.com:5380'
}

# Request a certificate
New-PACertificate example.com -Plugin Technitium -PluginArgs $pArgs
```

### Example: Wildcard Certificate with HTTP Protocol

```powershell
$token = Read-Host -Prompt "Enter Technitium API Token" -AsSecureString

$pArgs = @{
    TechnitiumToken = $token
    TechnitiumServer = '192.168.1.100:5380'
    TechnitiumProtocol = 'http'
}

New-PACertificate '*.example.com','example.com' -Plugin Technitium -PluginArgs $pArgs
```

### Example: Using Saved Credentials

```powershell
# Save the token to a variable (persists in session)
$token = Read-Host -Prompt "Enter Technitium API Token" -AsSecureString

$pArgs = @{
    TechnitiumToken = $token
    TechnitiumServer = 'dns.example.com:5380'
    TechnitiumProtocol = 'https'
    TechnitiumTTL = 300
}

# Request multiple certificates using the same credentials
New-PACertificate example.com -Plugin Technitium -PluginArgs $pArgs
New-PACertificate 'www.example.com' -Plugin Technitium -PluginArgs $pArgs
```

## Testing the Plugin

Before requesting an actual certificate, it's recommended to test that the plugin can successfully create and remove TXT records:

```powershell
# Setup
$token = Read-Host -Prompt "Enter Technitium API Token" -AsSecureString
$pArgs = @{
    TechnitiumToken = $token
    TechnitiumServer = 'dns.example.com:5380'
}

# Get current account
$acct = Get-PAAccount

# Test adding a record
Publish-Challenge example.com -Account $acct -Token 'fake-token-for-testing' -Plugin Technitium -PluginArgs $pArgs -Verbose

# Verify the TXT record exists in Technitium DNS console
# Then test removing it
Unpublish-Challenge example.com -Account $acct -Token 'fake-token-for-testing' -Plugin Technitium -PluginArgs $pArgs -Verbose
```

## Security Considerations

### Understanding API Token Permissions

This plugin uses Technitium DNS Server's HTTP API for DNS record management. It's important to understand the security implications:

**API Token Scope:**
- The API token grants modification rights to **all records** in the zones the user has access to
- Technitium currently does **not** support granular per-record permissions via the API
- If the token is compromised, an attacker can modify any record type (A, MX, NS, CNAME, etc.) in the permitted zones

**Recommended Security Practices:**

1. **Use a Dedicated User Account**
   - Never use an API token generated for the admin user
   - Create a dedicated user (e.g., "acme-user") with minimal zone access
   - Only grant permissions to zones that need ACME certificates
   - This limits the blast radius if the token is compromised

2. **Restrict Network Access**
   - The API shares the same ports as the web console (HTTP: 5380, HTTPS: 53443)
   - Use firewall rules at the network/OS level to restrict access to these ports to trusted IP addresses only
   - HTTPS is **strongly recommended** for production to protect the token in transit

3. **Token Management**
   - Store the API token securely
   - Rotate the token periodically (e.g., every 6 months)
   - Monitor Technitium's audit logs for unexpected changes
   - Revoke compromised tokens immediately

By following these practices, you can significantly reduce the security risks associated with using API tokens for automated certificate management.

## Tips

- Always include the port in the `TechnitiumServer` parameter (default: 5380 for HTTP, 53443 for HTTPS). If you've configured Technitium to use different ports, adjust accordingly
- For troubleshooting connection issues, try using `-TechnitiumProtocol 'http'` temporarily to rule out SSL/TLS problems
- Use the `-Verbose` flag with Posh-ACME commands to see detailed plugin operation
- The default TTL of 3600 seconds (1 hour) is appropriate for most use cases, but can be adjusted via `TechnitiumTTL` if needed