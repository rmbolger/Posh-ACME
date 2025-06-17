<#
.SYNOPSIS
    Posh-ACME DNS plugin for TransIP

.DESCRIPTION
    Implements DNS-01 for TransIP.
#>

# Returns the plugin type for Posh-ACME (required interface)
function Get-CurrentPluginType { 'dns-01' }

function Get-TransIPJwtToken {
    param(
        [Parameter(Mandatory)][string]$CustomerName,
        [Parameter(Mandatory)][string]$PrivateKey,
        [Parameter(Mandatory)][bool]$GlobalKey,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # 1. Compose payload required by TransIP
    $nonce = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})
    $randomNum = Get-Random -Minimum 10000 -Maximum 99999
    $label = "Posh-ACME-$randomNum"
    $tokenBody = @{
        login           = $CustomerName
        nonce           = $nonce
        global_key      = $GlobalKey
        expiration_time = "5 minutes"
        label           = $label
    } | ConvertTo-Json -Compress
    # 2. Sign the JSON body with SHA512/PKCS1
    $rsa = [System.Security.Cryptography.RSA]::Create()
    $rsa.ImportFromPem($PrivateKey)
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($tokenBody)
    $sigRaw = $rsa.SignData($bodyBytes,
        [System.Security.Cryptography.HashAlgorithmName]::SHA512,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $sigB64 = [Convert]::ToBase64String($sigRaw)
    # 3. Add the base64 signature as the HTTP header
    $headers = @{ Signature = $sigB64 }
    # 4. POST to TransIP
    $response = Invoke-RestMethod -Uri "$ApiEndpoint/auth" -Method Post -Body $tokenBody -Headers $headers -ContentType "application/json"
    return $response.token

    <#
    .SYNOPSIS
        Retrieves a JWT token for authenticating with the TransIP API.

    .DESCRIPTION
        Authenticates with the TransIP API by posting a signed request, returning a short-lived JWT used for subsequent API calls.

    .PARAMETER CustomerName
        Your TransIP account login.

    .PARAMETER PrivateKey
        The private RSA key as a PEM-formatted string.

    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for the entire account.

    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.

    .RETURNS
        The JWT token as a string.

    .EXAMPLE
        $token = Get-TransIPJwtToken -CustomerName 'transipuser' -PrivateKey $pem -GlobalKey $true
    #>

}

function Find-TransIPRootDomain {
    param(
        # The (sub)domain to search for
        [Parameter(Mandatory)][string]$RecordName,
        # TransIP API token for authentication
        [Parameter(Mandatory)][string]$Token,
        # Optional API endpoint
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Prepare API headers with bearer token
    $headers = @{ Authorization = "Bearer $Token" }
    # Request the list of domains on your account
    $domainList = (Invoke-RestMethod -Uri "$ApiEndpoint/domains" -Headers $headers).domains

    $found = $null
    $longest = 0
    # Try to match the record to the most specific root domain
    foreach ($d in $domainList) {
	$domainName = $d.name  # Get the actual domain name string
        # Check if domain name matches or suffix-matches the record name
        if ($RecordName -eq $domainName -or $RecordName -like "*.$domainName") {
            # Prefer longest match (most specific)
            if ($domainName.Length -gt $longest) {
                $found = $domainName
                $longest = $domainName.Length
            }
        }
    }
    # Return the matched root domain or $null if not found
    return $found

    <#
    .SYNOPSIS
        Finds the root domain for a given DNS record.

    .DESCRIPTION
        Given a full DNS record name and an authenticated API token, queries your TransIP account and matches the record to the appropriate root domain managed under your account.

    .PARAMETER RecordName
        The full (sub)domain to locate, e.g. _acme-challenge.example.com.

    .PARAMETER Token
        TransIP API JWT token.

    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.

    .RETURNS
        The best matching domain name as a string, or $null if not found.

    .EXAMPLE
        $root = Find-TransIPRootDomain -RecordName '_acme-challenge.example.com' -Token $token
    #>


}

function Get-TransIPRelativeName {
    param(
        # Full DNS record (e.g. _acme-challenge.domain.com)
        [Parameter(Mandatory)][string]$RecordName,
        # The matched root domain (e.g. domain.com)
        [Parameter(Mandatory)][string]$RootDomain
    )
    # Return "@" if the full record is the apex/root
    if ($RecordName -eq $RootDomain) { return '@' }
    # Strip the root domain suffix to get just the relative/friendly name
    $ending = ".$RootDomain"
    if ($RecordName -like "*$ending") {
        return $RecordName.Substring(0, $RecordName.Length - $ending.Length)
    } else {
        return $RecordName
    }
    <#
    .SYNOPSIS
        Computes the relative record name for a DNS entry.

    .DESCRIPTION
        Given the full record and the root domain, returns the relative (friendly) subdomain portion as needed by the TransIP API, or '@' for the apex/root.

    .PARAMETER RecordName
        Full DNS record name, e.g. _acme-challenge.example.com

    .PARAMETER RootDomain
        The matched root domain, e.g. example.com

    .RETURNS
        The relative record name as a string.

    .EXAMPLE
        Get-TransIPRelativeName -RecordName _acme-challenge.example.com -RootDomain example.com
    #>

}

function Add-DnsTxt {
    param(
        # Full DNS record (e.g. _acme-challenge.domain.com)
        [Parameter(Mandatory,Position=0)][string]$RecordName,
        # The TXT value to add (ACME challenge)
        [Parameter(Mandatory,Position=1)][string]$TxtValue,
        # Account login for authentication
        [Parameter(Mandatory)][string]$CustomerName,
        # The private key (PEM string)
        [Parameter(Mandatory)][string]$PrivateKey,
        # Boolean specifying if global/private key is used
        [Parameter(Mandatory)][bool]$GlobalKey,
        # Optional API endpoint override
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Obtain TransIP API token
    $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKey $PrivateKey -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    # Find the root domain corresponding to the record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    # Abort if the root domain cannot be determined
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Compute the name relative to the root domain (subdomain or "@")
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Create headers for API requests
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    # Read all current DNS entries for this domain
    $result = Invoke-RestMethod -Uri $getUri -Method GET -Headers $headers
    $records = $result.dnsEntries
    # Check if the desired TXT record already exists
    $exists = $records | Where-Object {
        $_.name -eq $RelativeName -and $_.type -eq "TXT" -and $_.content -eq $TxtValue
    }
    # If record exists, output and exit
    if ($exists) {
        Write-Verbose "TXT record '$RelativeName' with value '$TxtValue' already exists at $RootDomain. No action needed."
        return
    }
    # Formulate the body for the new TXT record
    $postUri = "$ApiEndpoint/domains/$RootDomain/dns"
	$body = @{
	    dnsEntry = @{
	        name    = $RelativeName
	        type    = "TXT"
        	content = $TxtValue
	        expire  = 300
	    }
	}

    # Send the Add DNS request to TransIP API
    Invoke-RestMethod -Uri $postUri -Method POST -Headers $headers -Body ($body | ConvertTo-Json) -ContentType 'application/json'

    <#
    .SYNOPSIS
        Adds a TXT record via the TransIP API.

    .DESCRIPTION
        Authenticates to the TransIP API, finds the appropriate root domain, and creates a new TXT entry for a DNS-01 ACME challenge if it does not already exist.

    .PARAMETER RecordName
        The full DNS record (e.g. _acme-challenge.example.com).

    .PARAMETER TxtValue
        The value for the TXT record.

    .PARAMETER CustomerName
        Your TransIP account login.

    .PARAMETER PrivateKey
        Your RSA private key (PEM string).

    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for your TransIP account.

    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.

    .EXAMPLE
        Add-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'txt-challenge' -CustomerName 'transipuser' -PrivateKey $pem -GlobalKey $true
    #>
}

function Remove-DnsTxt {
    param(
        # Full DNS record (e.g. _acme-challenge.domain.com)
        [Parameter(Mandatory,Position=0)][string]$RecordName,
        # The TXT value to remove (ACME challenge)
        [Parameter(Mandatory,Position=1)][string]$TxtValue,
        # Account login for authentication
        [Parameter(Mandatory)][string]$CustomerName,
        # The private key (PEM string)
        [Parameter(Mandatory)][string]$PrivateKey,
        # Boolean specifying if global/private key is used
        [Parameter(Mandatory)][bool]$GlobalKey,
        # Optional API endpoint override
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Obtain TransIP API token
    $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKey $PrivateKey -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    # Find the root domain for this record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    # Abort if root domain not determined
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Compute relative DNS name
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Prepare API header
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    # Read all current DNS entries for this domain
    $records = (Invoke-RestMethod -Uri $getUri -Headers $headers).dnsEntries
    # Check if the specific TXT record exists
    $toDelete = $records | Where-Object {
        $_.name -eq $RelativeName -and $_.type -eq "TXT" -and $_.content -eq $TxtValue
    }
    # If record does not exist, output and exit
    if (-not $toDelete) {
        Write-Verbose "TXT record '$RelativeName' with value '$TxtValue' does not exist at $RootDomain. No action needed."
        return
    }
    # Prepare DELETE URI for the DNS entry
    $deleteUri = "$ApiEndpoint/domains/$RootDomain/dns/$RelativeName"

    $body = @{
        dnsEntry = @{
            name    = $RelativeName
            type    = "TXT"
            content = $TxtValue
            expire = 300
        }
    }

    # Send DELETE request to remove the DNS entry from TransIP
    Invoke-RestMethod -Uri $deleteUri -Method DELETE -Headers $headers -Body ($body | ConvertTo-Json) -ContentType 'application/json'

    <#
    .SYNOPSIS
        Removes a TXT record via the TransIP API.

    .DESCRIPTION
        Authenticates to the TransIP API, finds the appropriate root domain, and deletes the specified TXT entry from your DNS records.

    .PARAMETER RecordName
        The full DNS record (e.g. _acme-challenge.example.com).

    .PARAMETER TxtValue
        The value for the TXT record to remove.

    .PARAMETER CustomerName
        Your TransIP account login.

    .PARAMETER PrivateKey
        Your RSA private key (PEM string).

    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for your TransIP account.

    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.

    .EXAMPLE
        Remove-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'txt-challenge' -CustomerName 'transipuser' -PrivateKey $pem -GlobalKey $true
    #>
}

function Get-DnsTxt {
    param(
        # Full DNS record (e.g. _acme-challenge.domain.com)
        [Parameter(Mandatory,Position=0)][string]$RecordName,
        # Account login for authentication
        [Parameter(Mandatory,Position=1)][string]$CustomerName,
        # The private key (PEM string)
        [Parameter(Mandatory)][string]$PrivateKey,
        # Boolean specifying if global/private key is used
        [Parameter(Mandatory)][bool]$GlobalKey,
        # Optional API endpoint override
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Obtain TransIP API token
    $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKey $PrivateKey -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    # Find root domain for provided record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    # Abort if root domain not determined
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Get relative name to root domain
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Prepare API header
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    # Get all DNS entries for the domain
    $records = (Invoke-RestMethod -Uri $getUri -Headers $headers).dnsEntries
    # Filter only relevant TXT records and return the value(s)
    $txtRecords = $records | Where-Object {
        $_.name -eq $RelativeName -and $_.type -eq "TXT"
    }
    return ($txtRecords.content)

    <#
    .SYNOPSIS
        Retrieves TXT DNS records for a given entry.

    .DESCRIPTION
        Authenticates to the TransIP API, finds the appropriate root domain, and fetches all TXT records associated with the specified record name.

    .PARAMETER RecordName
        The full DNS record (e.g. _acme-challenge.example.com).

    .PARAMETER CustomerName
        Your TransIP account login.

    .PARAMETER PrivateKey
        Your RSA private key (PEM string).

    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for your TransIP account.

    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.

    .RETURNS
        An array of TXT record values.

    .EXAMPLE
        Get-DnsTxt -RecordName '_acme-challenge.example.com' -CustomerName 'transipuser' -PrivateKey $pem -GlobalKey $true
    #>
}

# Dummy function for compatibility (not needed for TransIP)
function Save-DnsTxt { 
	param(
		$RecordName,
	        $TxtValue,
		$CustomerName,
                $PrivateKey,
		$GlobalKey,
		$ApiEndpoint)

}
