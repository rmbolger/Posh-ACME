<# 
.SYNOPSIS
    Posh-ACME DNS plugin for TransIP

.DESCRIPTION
    Implements DNS-01 for TransIP, supporting both private key authentication 
    (as SecureString or PEM file) and JWT AccessToken.
    Compatible with Windows Powershell 5.1 and PowerShell 7+.
    Supports both PKCS#1 and TransIP's PKCS#8 key formats on all platforms.
    PKCS#8 key format support on WinPS5.1 requires .NET 4.7.2+ / Win10+ or Server2016+  
#>

function Get-CurrentPluginType { 'dns-01' }

function Get-TransIPPrivateKey {
    param (
        [Parameter(Mandatory=$false)] [System.Security.SecureString]$PrivateKeySecureString,
        [Parameter(Mandatory=$false)] [string]$PrivateKeyFilePath
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
            } finally {
                # Wipe BSTR memory after use for security
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($unmanaged)
            }
        } elseif ($PrivateKeyFilePath) {
            # Load from supplied file path (should be protected by NTFS permissions)
            if (-not (Test-Path $PrivateKeyFilePath)) {
                throw "Private key file not found: $PrivateKeyFilePath"
            }
            $pem = Get-Content -Raw -Path $PrivateKeyFilePath
        } else {
            # Neither key method supplied
            throw "No private key provided. Supply -PrivateKeySecureString or -PrivateKeyFilePath."
        }
        # Validate PEM string exists
        if (-not $pem) { throw "Failed to load PEM private key content." }
        return $pem
    } finally {
        # Sensitive variables are cleared by calling code
    }
<# 
.SYNOPSIS
    Securely loads the RSA private key as a PEM string.
.DESCRIPTION
    Loads the private key from either a SecureString (preferred) or a file path.
    Sensitive variables are cleared ASAP.
.PARAMETER PrivateKeySecureString
    Private key as SecureString.
.PARAMETER PrivateKeyFilePath
    File path to PEM key.
.OUTPUTS
    PEM-formatted private key string.
#>
}

function Import-RsaPrivateKey {
    param (
        [Parameter(Mandatory)][string]$PemString
    )
    # For PowerShell 7+, use the native ImportFromPem method
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportFromPem($PemString)
        return $rsa
    }
    # On PS5.1 — support both PKCS#1 and PKCS#8
    $clean = $PemString -replace "\r","" -replace "\n",""
    if ($clean -match '-----BEGIN RSA PRIVATE KEY-----') {
        # PKCS#1 (classic OpenSSL)
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
        # PKCS#8 (modern OpenSSL export)
        $base64 = ($PemString -split "\r?\n" | Where-Object {$_ -notmatch "^-+.*PRIVATE KEY-+$"}) -join ""
        $pkcs8bytes = [Convert]::FromBase64String($base64)
        try {
            $cngKey = [System.Security.Cryptography.CngKey]::Import($pkcs8bytes, [System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
            $rsaCng = New-Object System.Security.Cryptography.RSACng($cngKey)
            return $rsaCng
        } catch {
            throw "Could not import PKCS#8 key in Windows PowerShell 5.1. Only supported in updated environments. Error details: $_"
        }
    } else {
        throw "Unrecognized private key PEM format. Only PKCS#1 (BEGIN RSA PRIVATE KEY) and PKCS#8 (BEGIN PRIVATE KEY) are supported."
    }
    <# 
    .SYNOPSIS
        Imports a PEM-encoded RSA private key.
    .DESCRIPTION
        Supports PS7+ natively and emulates PKCS#1 parsing for PS5.1.
    .PARAMETER PemString
        PEM private key string.
    .OUTPUTS
        [System.Security.Cryptography.RSA] (PS7+) or [System.Security.Cryptography.RSACryptoServiceProvider] (PS5.1)
    #>
}

function Get-TransIPJwtToken {
    param (
        [Parameter(Mandatory)] [string]$CustomerName,
        [Parameter(Mandatory)] [bool]$GlobalKey,
        [Parameter()][System.Security.SecureString]$PrivateKeySecureString,
        [Parameter()][string]$PrivateKeyFilePath,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Retrieve private key contents
    $PrivateKey = Get-TransIPPrivateKey -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath
    $rsa = Import-RsaPrivateKey -PemString $PrivateKey

    try {
        # Build a random nonce and JWT label for security and logging
        $nonce = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
        $randomNum = Get-Random -Minimum 10000 -Maximum 99999
        $label = "Posh-ACME-$randomNum"
        $tokenBody = @{
            login = $CustomerName
            nonce = $nonce
            global_key = $GlobalKey
            expiration_time = "5 minutes"
            label = $label
        } | ConvertTo-Json -Compress
        # Sign the body using SHA512 PKCS#1
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($tokenBody) 
        $sigRaw = $rsa.SignData($bodyBytes,[System.Security.Cryptography.HashAlgorithmName]::SHA512,[System.Security.Cryptography.RSASignaturePadding]::Pkcs1) 
        $sigB64 = [Convert]::ToBase64String($sigRaw)
        # Call TransIP /auth endpoint for JWT
        $headers = @{ Signature = $sigB64 }
        $response = Invoke-RestMethod -Uri "$ApiEndpoint/auth" -Method Post -Body $tokenBody -Headers $headers -ContentType "application/json"
        return $response.token
    } finally {
        # Clear private key material as soon as possible
        $PrivateKey = $null
        if ($rsa -is [System.Security.Cryptography.RSACryptoServiceProvider]) { $rsa.Clear() }
    }
    <# 
    .SYNOPSIS
        Retrieves a JWT token for authenticating with the TransIP API.
    .DESCRIPTION
        Authenticates with the TransIP API and returns a short-lived JWT for subsequent calls.
    .PARAMETER CustomerName
        Your TransIP username/login.
    .PARAMETER PrivateKeySecureString
        (Preferred) Private key as SecureString.
    .PARAMETER PrivateKeyFilePath
        PEM key file path.
    .PARAMETER GlobalKey
        Use the global API key for account.
    .PARAMETER ApiEndpoint
        Optional override for the TransIP API endpoint.
    .RETURNS
        JWT token string.
    .EXAMPLE
        $token = Get-TransIPJwtToken -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    #>
}

function Find-TransIPRootDomain {
    param (
        [Parameter(Mandatory)] [string]$RecordName,
        [Parameter(Mandatory)] [string]$Token,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Prepare Bearer authentication header
    $headers = @{ Authorization = "Bearer $Token" }
    # Get all domains under the account
    $domainList = (Invoke-RestMethod -Uri "$ApiEndpoint/domains" -Headers $headers).domains
    $found = $null
    $longest = 0
    # Look for the most specific (longest) root domain that is part of the record
    foreach ($d in $domainList) {
        $domainName = $d.name
        if ($RecordName -eq $domainName -or $RecordName -like "*.$domainName") {
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
        Given a full DNS record name, queries your TransIP domains and matches to the longest (most specific) managed domain.
    .PARAMETER RecordName
        Full (sub)domain to locate.
    .PARAMETER Token
        TransIP API JWT.
    .PARAMETER ApiEndpoint
        Optional override for endpoint.
    .RETURNS
        Domain name or $null.
    .EXAMPLE
        $root = Find-TransIPRootDomain -RecordName '_acme-challenge.example.com' -Token $token
    #>
}

function Get-TransIPRelativeName {
    param (
        [Parameter(Mandatory)][string]$RecordName,
        [Parameter(Mandatory)][string]$RootDomain
    )
    # If record == root, return apex/at sign
    if ($RecordName -eq $RootDomain) { return '@' }
    $ending = ".$RootDomain"
    # Otherwise, remove the root domain from the record name
    if ($RecordName -like "*$ending") {
        return $RecordName.Substring(0, $RecordName.Length - $ending.Length)
    } else {
        return $RecordName
    }
    <# 
    .SYNOPSIS
        Computes the relative DNS record name for a DNS entry, for use with TransIP API.
    .DESCRIPTION
        Converts a full record name + root into the correct relative (sub)domain for TransIP API or @ for the root.
    .PARAMETER RecordName
        Full DNS record name.
    .PARAMETER RootDomain
        Matched root domain.
    .RETURNS
        Relative record or @.
    .EXAMPLE
        Get-TransIPRelativeName -RecordName _acme-challenge.example.com -RootDomain example.com
    #>
}

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'KeyAuth')]
    param (
        # Authentication, key or JWT
        [Parameter(ParameterSetName = 'KeyAuth', Mandatory=$true)] [string]$CustomerName,
        [Parameter(ParameterSetName = 'KeyAuth')] [System.Security.SecureString]$PrivateKeySecureString,
        [Parameter(ParameterSetName = 'KeyAuth')] [string]$PrivateKeyFilePath,
        [Parameter(ParameterSetName = 'KeyAuth', Mandatory=$true)] [bool]$GlobalKey,
        [Parameter(ParameterSetName = 'TokenAuth', Mandatory=$true)] [string]$AccessToken,
        # Standard DNS and config
        [Parameter(Mandatory=$true, Position=0)] [string]$RecordName,
        [Parameter(Mandatory=$true, Position=1)] [string]$TxtValue,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Decide token source: supplied or generated
    if ($PSCmdlet.ParameterSetName -eq 'TokenAuth') {
        # Use supplied JWT AccessToken directly
        $token = $AccessToken
    } else {
        # Get new token using private key
        $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    }
    # Find root domain for the record
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Strip root domain from record name for relative (sub)domain
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    # Prepare Bearer header for all API calls
    $headers = @{ Authorization = "Bearer $token" }
    # Query existing records to check for duplicates
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    $result = Invoke-RestMethod -Uri $getUri -Method GET -Headers $headers
    $records = $result.dnsEntries
    # If a TXT record for this value already exists, skip add
    $exists = $records | Where-Object { $_.name -eq $RelativeName -and $_.type -eq "TXT" -and $_.content -eq $TxtValue }
    if ($exists) {
        Write-Verbose "TXT record '$RelativeName' with value '$TxtValue' already exists at $RootDomain. No action needed."
        return
    }
    # None exists, so create new TXT DNS entry
    $postUri = "$ApiEndpoint/domains/$RootDomain/dns"
    $body = @{
        dnsEntry = @{
            name    = $RelativeName
            type    = "TXT"
            content = $TxtValue
            expire  = 300
        }
    }
    Invoke-RestMethod -Uri $postUri -Method POST -Headers $headers -Body ($body | ConvertTo-Json) -ContentType 'application/json'

    <# 
    .SYNOPSIS
        Adds a TXT record via the TransIP API.
    .DESCRIPTION
        Authenticates (private key/JWT), finds the correct domain, and adds a TXT if missing.
    .PARAMETER CustomerName
        TransIP account login.
    .PARAMETER PrivateKeySecureString
        (Preferred) PEM private key as SecureString.
    .PARAMETER PrivateKeyFilePath
        PEM key file path.
    .PARAMETER GlobalKey
        Indicates whether key is global.
    .PARAMETER AccessToken
        JWT token. If supplied, Posh-ACME will skip Get-TransIPJwtToken.
    .PARAMETER RecordName
        The full DNS record (typically _acme-challenge.domain.com).
    .PARAMETER TxtValue
        TXT value to create.
    .PARAMETER ApiEndpoint
        (Optional) Override for TransIP API.
    .EXAMPLE
        Add-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'val' -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    .EXAMPLE
        Add-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'val' -AccessToken $token
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'KeyAuth')]
    param (
        [Parameter(ParameterSetName = 'KeyAuth', Mandatory=$true)] [string]$CustomerName,
        [Parameter(ParameterSetName = 'KeyAuth')] [System.Security.SecureString]$PrivateKeySecureString,
        [Parameter(ParameterSetName = 'KeyAuth')] [string]$PrivateKeyFilePath,
        [Parameter(ParameterSetName = 'KeyAuth', Mandatory=$true)] [bool]$GlobalKey,
        [Parameter(ParameterSetName = 'TokenAuth', Mandatory=$true)] [string]$AccessToken,
        [Parameter(Mandatory=$true, Position=0)] [string]$RecordName,
        [Parameter(Mandatory=$true, Position=1)] [string]$TxtValue,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Decide token source: supplied or generated
    if ($PSCmdlet.ParameterSetName -eq 'TokenAuth') {
        # Use supplied AccessToken
        $token = $AccessToken
    } else {
        # Generate JWT using the given keys
        $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    }
    # Identify root domain as before
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Relative name for deletion
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    $headers = @{ Authorization = "Bearer $token" }
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    $records = (Invoke-RestMethod -Uri $getUri -Headers $headers).dnsEntries
    $toDelete = $records | Where-Object { $_.name -eq $RelativeName -and $_.type -eq "TXT" -and $_.content -eq $TxtValue }
    if (-not $toDelete) {
        Write-Verbose "TXT record '$RelativeName' with value '$TxtValue' does not exist at $RootDomain. No action needed."
        return
    }
    # Build and submit delete call for DNS TXT entry
    $deleteUri = "$ApiEndpoint/domains/$RootDomain/dns/$RelativeName"
    $body = @{
        dnsEntry = @{
            name    = $RelativeName
            type    = "TXT"
            content = $TxtValue
            expire  = 300
        }
    }
    Invoke-RestMethod -Uri $deleteUri -Method DELETE -Headers $headers -Body ($body | ConvertTo-Json) -ContentType 'application/json'
    <# 
    .SYNOPSIS
        Removes a TXT record via the TransIP API.
    .DESCRIPTION
        Authenticates (private key/JWT), finds the correct domain, and deletes a TXT if present.
    .PARAMETER CustomerName
        TransIP account login.
    .PARAMETER PrivateKeySecureString
        (Preferred) PEM private key as SecureString.
    .PARAMETER PrivateKeyFilePath
        PEM key file path.
    .PARAMETER GlobalKey
        Indicates whether key is global.
    .PARAMETER AccessToken
        JWT token. If supplied, Posh-ACME will skip Get-TransIPJwtToken.
    .PARAMETER RecordName
        The full DNS record (typically _acme-challenge.domain.com).
    .PARAMETER TxtValue
        TXT value to delete.
    .PARAMETER ApiEndpoint
        (Optional) Override for TransIP API.
    .EXAMPLE
        Remove-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'val' -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    .EXAMPLE
        Remove-DnsTxt -RecordName '_acme-challenge.example.com' -TxtValue 'val' -AccessToken $token
    #>
}

function Get-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'KeyAuth')]
    param (
        [Parameter(ParameterSetName = 'KeyAuth', Mandatory=$true)] [string]$CustomerName,
        [Parameter(ParameterSetName = 'KeyAuth')] [System.Security.SecureString]$PrivateKeySecureString,
        [Parameter(ParameterSetName = 'KeyAuth')] [string]$PrivateKeyFilePath,
        [Parameter(ParameterSetName = 'KeyAuth', Mandatory=$true)] [bool]$GlobalKey,
        [Parameter(ParameterSetName = 'TokenAuth', Mandatory=$true)] [string]$AccessToken,
        [Parameter(Mandatory=$true, Position=0)] [string]$RecordName,
        [Parameter()][string]$ApiEndpoint = "https://api.transip.nl/v6"
    )
    # Decide token source: supplied or generated
    if ($PSCmdlet.ParameterSetName -eq 'TokenAuth') {
        # Use AccessToken directly
        $token = $AccessToken
    } else {
        # Otherwise generate using private key
        $token = Get-TransIPJwtToken -CustomerName $CustomerName -PrivateKeySecureString $PrivateKeySecureString -PrivateKeyFilePath $PrivateKeyFilePath -GlobalKey $GlobalKey -ApiEndpoint $ApiEndpoint
    }
    # Find appropriate root domain
    $RootDomain = Find-TransIPRootDomain -RecordName $RecordName -Token $token -ApiEndpoint $ApiEndpoint
    if (-not $RootDomain) { throw "Could not determine root domain for $RecordName" }
    # Convert to relative/sub domain
    $RelativeName = Get-TransIPRelativeName -RecordName $RecordName -RootDomain $RootDomain
    $headers = @{ Authorization = "Bearer $token" }
    # Query for all DNS records for this domain
    $getUri = "$ApiEndpoint/domains/$RootDomain/dns"
    $records = (Invoke-RestMethod -Uri $getUri -Headers $headers).dnsEntries
    # Filter TXT records for the requested relative name
    $txtRecords = $records | Where-Object { $_.name -eq $RelativeName -and $_.type -eq "TXT" }
    # Return all TXT values as array
    return ($txtRecords.content)
    <# 
    .SYNOPSIS
        Retrieves TXT DNS records for a given entry.
    .DESCRIPTION
        Authenticates (private key/JWT), finds the root domain, and lists all TXT.
    .PARAMETER CustomerName
        TransIP account login.
    .PARAMETER PrivateKeySecureString
        (Preferred) PEM private key as SecureString.
    .PARAMETER PrivateKeyFilePath
        PEM key file path.
    .PARAMETER GlobalKey
        Indicates whether key is global.
    .PARAMETER AccessToken
        JWT token. If supplied, Posh-ACME will skip Get-TransIPJwtToken.
    .PARAMETER RecordName
        The full DNS record (typically _acme-challenge.domain.com).
    .PARAMETER ApiEndpoint
        (Optional) Override for TransIP API.
    .RETURNS
        Array of TXT values.
    .EXAMPLE
        Get-DnsTxt -RecordName '_acme-challenge.example.com' -CustomerName 'transipuser' -PrivateKeySecureString $sec -GlobalKey $true
    .EXAMPLE
        Get-DnsTxt -RecordName '_acme-challenge.example.com' -AccessToken $token
    #>
}

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
    # intentionally does nothing for TransIP
}
