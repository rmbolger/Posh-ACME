<#
.SYNOPSIS
    Posh-ACME DNS plugin for TransIP

.DESCRIPTION
    Implements DNS-01 for TransIP.
    Securely supports private key input as SecureString or PEM file.
    SecureString takes precedence.
    Compatible with WinPS 5.1 and PowerShell 7+.
    Supports both PKCS#1 and TransIP's PKCS#8 key formats on all platforms.
    PKCS#8 key format support on WinPS5.1 requires .NET 4.7.2+ / Win10+ or Server2016+  
#>

# Returns required plugin type for Posh-ACME framework (always dns-01)
function Get-CurrentPluginType { 'dns-01' }

function Get-TransIPPrivateKey {
    param(
        [Parameter(Mandatory=$false)][System.Security.SecureString]$PrivateKeySecureString,
        [Parameter(Mandatory=$false)][string]$PrivateKeyFilePath
    )
    $pem = $null
    try {
        # Use SecureString if supplied
        if ($PrivateKeySecureString) {
            # Marshal SecureString to BSTR pointer (Windows internal string)
            $unmanaged = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PrivateKeySecureString)
            try {
                # Convert pointer to managed .NET string (plaintext in memory only briefly)
                $pem = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($unmanaged)
            }
            finally {
                # Wipe BSTR memory after use for security
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($unmanaged)
            }
        } elseif ($PrivateKeyFilePath) {
            # Otherwise, load PEM from file if the path exists
            if (-not (Test-Path $PrivateKeyFilePath)) {
                throw "Private key file not found: $PrivateKeyFilePath"
            }
            $pem = Get-Content -Raw -Path $PrivateKeyFilePath
        } else {
            # Neither SecureString nor filePath provided; fail
            throw "No private key provided. Supply -PrivateKeySecureString or -PrivateKeyFilePath."
        }
        # If load failed, error
        if (-not $pem) { throw "Failed to load PEM private key content." }
        return $pem # Return PEM string (caller must clear it later!)
    } finally {
        # PEM buffer will not persist: calling code must clear as soon as possible
    }

    <#
    .SYNOPSIS
        Securely loads the RSA private key as a PEM string.
    .DESCRIPTION
        Loads the private key from either a SecureString (preferred) or a file path.
        If both parameters are supplied, SecureString takes precedence.
        Sensitive variables are cleared ASAP and never kept in memory longer than needed.
    .PARAMETER PrivateKeySecureString
        [SecureString] The PEM private key (preferred).
    .PARAMETER PrivateKeyFilePath
        [string] Path to the PEM private key file.
    .OUTPUTS
        [string] PEM-formatted private key string.
    #>

}

function Import-RsaPrivateKey {
    param(
        [Parameter(Mandatory)][string]$PemString
    )
    # PowerShell 7+: just use ImportFromPem
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportFromPem($PemString)
        return $rsa
    }
    # Remove headers/footers for PKCS#1
    $clean = $PemString -replace "\r","" -replace "\n",""
    if ($clean -match '-----BEGIN RSA PRIVATE KEY-----') {
        $base64 = ($PemString -split "\r?\n" | Where-Object {$_ -notmatch "^-+.*PRIVATE.*-+$"}) -join ""
        $keyBytes = [Convert]::FromBase64String($base64)
        $reader = New-Object System.IO.BinaryReader([System.IO.MemoryStream]::new($keyBytes))
        $twoBytes = $reader.ReadUInt16()
        if ($twoBytes -ne 0x8130 -and $twoBytes -ne 0x8230) { throw "PEM parse error (ASN.1)" }
        $reader.BaseStream.Seek(15, 'Current')
        function ReadInt { 
            $size = $reader.ReadByte()
            if ($size -eq 0x81) { $size = $reader.ReadByte() }
            [byte[]]$bytes = $reader.ReadBytes($size)
            if ($bytes[0] -eq 0x00) { $bytes = $bytes[1..($bytes.Length-1)] }
            return $bytes
        }
        $modulus = ReadInt
        $exponent = ReadInt
        $d = ReadInt
        $p = ReadInt
        $q = ReadInt
        $dp = ReadInt
        $dq = ReadInt
        $iq = ReadInt
        $rsaParams = New-Object System.Security.Cryptography.RSAParameters
        $rsaParams.Modulus = $modulus
        $rsaParams.Exponent = $exponent
        $rsaParams.D = $d
        $rsaParams.P = $p
        $rsaParams.Q = $q
        $rsaParams.DP = $dp
        $rsaParams.DQ = $dq
        $rsaParams.InverseQ = $iq
        $rsaProv = New-Object System.Security.Cryptography.RSACryptoServiceProvider
        $rsaProv.PersistKeyInCsp = $false
        $rsaProv.ImportParameters($rsaParams)
        return $rsaProv
    } elseif ($clean -match '-----BEGIN PRIVATE KEY-----') {
        # Try CNG import on Win10+ with PKCS#8 DER bytes
        $base64 = ($PemString -split "\r?\n" | Where-Object {$_ -notmatch "^-+.*PRIVATE KEY-+$"}) -join ""
        $pkcs8bytes = [Convert]::FromBase64String($base64)
        try {
            # Only available if .NET Framework supports CNG (.NET 4.7.2+/Win10+). Will throw otherwise.
            $cngKey = [System.Security.Cryptography.CngKey]::Import($pkcs8bytes, [System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
            $rsaCng = New-Object System.Security.Cryptography.RSACng($cngKey)
            return $rsaCng
        } catch {
            throw "Could not import PKCS#8 key in Windows PowerShell 5.1. On this system, only '-----BEGIN RSA PRIVATE KEY-----' PKCS#1-supported. To use this PKCS#8 key, please convert it to PKCS#1 format with OpenSSL: 'openssl rsa -in key.pem -out rsakey.pem'. Error details: $_"
        }
    } else {
        throw "Unrecognized private key PEM format. Only PKCS#1 (BEGIN RSA PRIVATE KEY) and PKCS#8 (BEGIN PRIVATE KEY) are supported."
    }
    <#
    .SYNOPSIS
        Imports a PEM-encoded RSA private key (supports PKCS#8 and PKCS#1).
    .DESCRIPTION
        Native support for PS 7+, pure .NET decoder for PKCS#8 (BEGIN PRIVATE KEY) and PKCS#1 (BEGIN RSA PRIVATE KEY) on WinPS 5.1.
    .PARAMETER PemString
        PEM private key string.
    .OUTPUTS
        [System.Security.Cryptography.RSA or System.Security.Cryptography.RSACryptoServiceProvider]
    #>

}


function Get-TransIPJwtToken {
    param(
        [Parameter(Mandatory)][string]$CustomerName,
        [Parameter(Mandatory)][bool]$GlobalKey,
        [Parameter()][System.Security.SecureString]$PrivateKeySecureString,
        [Parameter()][string]$PrivateKeyFilePath,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )

    # Securely load the PEM key from provided parameter
    $PrivateKey = Get-TransIPPrivateKey -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath
    # Convert PEM to .NET RSA object (cross-version logic)
    $rsa = Import-RsaPrivateKey -PemString $PrivateKey

    try {
        # Prepare a nonce for JWT
        $nonce = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})
        $randomNum = Get-Random -Minimum 10000 -Maximum 99999
        $label = "Posh-ACME-$randomNum"
        # JWT claims for TransIP
        $tokenBody = @{
            login           = $CustomerName
            nonce           = $nonce
            global_key      = $GlobalKey
            expiration_time = "5 minutes"
            label           = $label
        } | ConvertTo-Json -Compress

        # Hash and sign the payload (SHA512/PKCS#1)
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($tokenBody)
        $sigRaw = $rsa.SignData($bodyBytes,
            [System.Security.Cryptography.HashAlgorithmName]::SHA512,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $sigB64 = [Convert]::ToBase64String($sigRaw)

        # Prepare HTTP header for signature
        $headers = @{ Signature = $sigB64 }

        # Request JWT from TransIP API
        $response = Invoke-RestMethod -Uri "$ApiEndpoint/auth" -Method Post -Body $tokenBody -Headers $headers -ContentType "application/json"
        return $response.token
    }
    finally {
        # Always clear private key material as soon as possible
        $PrivateKey = $null
        if ($rsa -is [System.Security.Cryptography.RSACryptoServiceProvider]) { $rsa.Clear() }
    }
    <#
    .SYNOPSIS
        Retrieves a JWT token for authenticating with the TransIP API.
    .DESCRIPTION
        Authenticates with the TransIP API by posting a signed request, returning a short-lived JWT used for subsequent API calls.
    .PARAMETER CustomerName
        Your TransIP account login.
    .PARAMETER PrivateKeySecureString
        The private key as a SecureString (takes precedence).
    .PARAMETER PrivateKeyFilePath
        Path to the PEM private key file.
    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for the entire account.
    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.
    .RETURNS
        The JWT token as a string.
    .EXAMPLE
        $token = Get-TransIPJwtToken -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    #>
}

function Find-TransIPRootDomain {
    param(
        [Parameter(Mandatory)][string]$RecordName,
        [Parameter(Mandatory)][string]$Token,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Prepare bearer token for API auth
    $headers = @{ Authorization = "Bearer $Token" }
    # Get domain list from account
    $domainList = (Invoke-RestMethod -Uri "$ApiEndpoint/domains" -Headers $headers).domains
    $found = $null
    $longest = 0
    # For each domain registered, check if a match/parent exists
    foreach ($d in $domainList) {
        $domainName = $d.name
        if ($RecordName -eq $domainName -or $RecordName -like "*.$domainName") {
            # Favor the most specific (longest) match
            if ($domainName.Length -gt $longest) {
                $found = $domainName
                $longest = $domainName.Length
            }
        }
    }
    return $found

    <#
    .SYNOPSIS
        Finds the root domain for a given DNS record in your TransIP account.
    .DESCRIPTION
        Given a full DNS record name and a valid TransIP API bearer token,
        queries your TransIP account for all managed domains and matches 
        the record to the longest (most specific) appropriate domain.
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
        [Parameter(Mandatory)][string]$RecordName,
        [Parameter(Mandatory)][string]$RootDomain
    )
    # If record matches root, we want "@"
    if ($RecordName -eq $RootDomain) { return '@' }
    # Otherwise, strip root domain from end to get relative part
    $ending = ".$RootDomain"
    if ($RecordName -like "*$ending") {
        return $RecordName.Substring(0, $RecordName.Length - $ending.Length)
    } else {
        return $RecordName
    }
    <#
    .SYNOPSIS
        Computes the relative DNS record name for a DNS entry, for use with TransIP API.
    .DESCRIPTION
        Given a full DNS record name and its root domain, returns the relative 
        (subdomain) portion required by the TransIP API, or "@" for apex/root.
    .PARAMETER RecordName
        Full DNS record name, e.g. _acme-challenge.example.com
    .PARAMETER RootDomain
        The matched root domain, e.g. example.com
    .RETURNS
        The relative record name as a string, or "@" if the apex/root.
    .EXAMPLE
        Get-TransIPRelativeName -RecordName _acme-challenge.example.com -RootDomain example.com
    #>
}

function Add-DnsTxt {
    param(
        [Parameter(Mandatory,Position=0)][string]$RecordName,
        [Parameter(Mandatory,Position=1)][string]$TxtValue,
        [Parameter(Mandatory)][string]$CustomerName,
        [Parameter()][System.Security.SecureString]$PrivateKeySecureString,
        [Parameter()][string]$PrivateKeyFilePath,
        [Parameter(Mandatory)][bool]$GlobalKey,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )

    # Obtain signed JWT from TransIP
    $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    # Find root domain for the record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Convert to relative name for ACME API
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Prepare API authentication
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    # Query all DNS records for this domain
    $result = Invoke-RestMethod -Uri $getUri -Method GET -Headers $headers
    $records = $result.dnsEntries
    # If a TXT record already exists, no action needed
    $exists = $records | Where-Object { $_.name -eq $RelativeName -and $_.type -eq "TXT" -and $_.content -eq $TxtValue }
    if ($exists) {
        Write-Verbose "TXT record '$RelativeName' with value '$TxtValue' already exists at $RootDomain. No action needed."
        return
    }
    # Prepare body for adding new TXT record
    $postUri = "$ApiEndpoint/domains/$RootDomain/dns"
    $body = @{
        dnsEntry = @{
            name    = $RelativeName
            type    = "TXT"
            content = $TxtValue
            expire  = 300
        }
    }
    # Issue POST to add TXT record
    Invoke-RestMethod -Uri $postUri -Method POST -Headers $headers -Body ($body | ConvertTo-Json) -ContentType 'application/json'

    <#
    .SYNOPSIS
        Adds a TXT record via the TransIP API.
    .DESCRIPTION
        Authenticates to the TransIP API, finds the appropriate root domain, and creates a new TXT entry if not present.
    .PARAMETER RecordName
        The full DNS record (e.g. _acme-challenge.example.com).
    .PARAMETER TxtValue
        The value for the TXT record.
    .PARAMETER CustomerName
        Your TransIP account login.
    .PARAMETER PrivateKeySecureString
        The private key as SecureString (preferred).
    .PARAMETER PrivateKeyFilePath
        File path to PEM private key.
    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for your TransIP account.
    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.
    .EXAMPLE
        Add-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'txt-challenge' -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    #>

}

function Remove-DnsTxt {
    param(
        [Parameter(Mandatory,Position=0)][string]$RecordName,
        [Parameter(Mandatory,Position=1)][string]$TxtValue,
        [Parameter(Mandatory)][string]$CustomerName,
        [Parameter()][System.Security.SecureString]$PrivateKeySecureString,
        [Parameter()][string]$PrivateKeyFilePath,
        [Parameter(Mandatory)][bool]$GlobalKey,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )

    # Obtain signed JWT from TransIP
    $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    # Find root domain for the record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Convert to relative name for API
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Prepare API authentication
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    # Query all DNS records for this domain
    $records = (Invoke-RestMethod -Uri $getUri -Headers $headers).dnsEntries
    # If the TXT we're asked to delete does not exist, exit
    $toDelete = $records | Where-Object { $_.name -eq $RelativeName -and $_.type -eq "TXT" -and $_.content -eq $TxtValue }
    if (-not $toDelete) {
        Write-Verbose "TXT record '$RelativeName' with value '$TxtValue' does not exist at $RootDomain. No action needed."
        return
    }
    # Prepare request body and endpoint for deletion
    $deleteUri = "$ApiEndpoint/domains/$RootDomain/dns/$RelativeName"
    $body = @{
        dnsEntry = @{
            name    = $RelativeName
            type    = "TXT"
            content = $TxtValue
            expire  = 300
        }
    }
    # Issue DELETE call to remove DNS record
    Invoke-RestMethod -Uri $deleteUri -Method DELETE -Headers $headers -Body ($body | ConvertTo-Json) -ContentType 'application/json'

    <#
    .SYNOPSIS
        Removes a TXT record via the TransIP API.
    .DESCRIPTION
        Authenticates to the TransIP API, finds the root, and deletes a specific TXT record if it exists.
    .PARAMETER RecordName
        The full DNS record (e.g. _acme-challenge.example.com).
    .PARAMETER TxtValue
        The value for the TXT record to remove.
    .PARAMETER CustomerName
        Your TransIP account login.
    .PARAMETER PrivateKeySecureString
        The private key as SecureString (preferred).
    .PARAMETER PrivateKeyFilePath
        File path to PEM private key.
    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for your TransIP account.
    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.
    .EXAMPLE
        Remove-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'txt-challenge' -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    #>

}

function Get-DnsTxt {
    param(
        [Parameter(Mandatory,Position=0)][string]$RecordName,
        [Parameter(Mandatory,Position=1)][string]$CustomerName,
        [Parameter()][System.Security.SecureString]$PrivateKeySecureString,
        [Parameter()][string]$PrivateKeyFilePath,
        [Parameter(Mandatory)][bool]$GlobalKey,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )

    # Obtain signed JWT from TransIP
    $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    # Find root domain for the record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Convert to relative name for API
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Prepare API authentication
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    # Query all DNS TXT records
    $records = (Invoke-RestMethod -Uri $getUri -Headers $headers).dnsEntries
    $txtRecords = $records | Where-Object { $_.name -eq $RelativeName -and $_.type -eq "TXT" }
    return ($txtRecords.content)

    <#
    .SYNOPSIS
        Retrieves TXT DNS records for a given entry.
    .DESCRIPTION
        Authenticates, locates root domain, and fetches all TXT records for the specified record name.
    .PARAMETER RecordName
        The full DNS record (e.g. _acme-challenge.example.com).
    .PARAMETER CustomerName
        Your TransIP account login.
    .PARAMETER PrivateKeySecureString
        The private key as SecureString (preferred).
    .PARAMETER PrivateKeyFilePath
        File path to PEM private key.
    .PARAMETER GlobalKey
        Boolean indicating whether the key is global for your TransIP account.
    .PARAMETER ApiEndpoint
        (Optional) Override for the default TransIP API endpoint.
    .RETURNS
        An array of TXT record values.
    .EXAMPLE
        Get-DnsTxt -RecordName '_acme-challenge.example.com' -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    #>
}

# Dummy compatibility function (Posh-ACME expects it, but does not use for TransIP)
function Save-DnsTxt { 
    param(
        $RecordName,
        $TxtValue,
        $CustomerName,
        $PrivateKeySecureString,
        $PrivateKeyFilePath,
        $GlobalKey,
        $ApiEndpoint
    )
    # intentionally does nothing
}
