function New-Jws {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='RSAKey',Mandatory,Position=0)]
        [Security.Cryptography.RSA]$RSAKey,
        [Parameter(ParameterSetName='ECKey',Mandatory,Position=0)]
        [Security.Cryptography.ECDsa]$ECKey,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$Header,
        [Parameter(Mandatory,Position=2)]
        [string]$PayloadJson
    )

    # RFC 7515 - JSON Web Signature (JWS)
    # https://tools.ietf.org/html/rfc7515

    # This is not a general JWS implementation. It will specifically
    # cater to making JWS messages for the ACME v2 protocol.
    # https://tools.ietf.org/html/draft-ietf-acme-acme-09

    # ACME messages should have either 'jwk' or 'kid' in the header.
    # It is assumed the caller has built the header properly for the call
    # being made.

    # validate the header
    if ('alg' -notin $Header.Keys -or $Header.alg -notin 'RS256','ES256') {
        throw "Missing or invalid 'alg' in supplied Header"
    }
    if (!('jwk' -in $Header.Keys -xor 'kid' -in $Header.Keys)) {
        if ('jwk' -in $Header.Keys) {
            throw "Conflicting key entries. Both 'jwk' and 'kid' found in supplied Header"
        } else {
            throw "Missing key entries. Neither 'jwk' or 'kid' found in supplied Header"
        }
    }
    if ('jwk' -in $Header.Keys -and [string]::IsNullOrWhiteSpace($Header.jwk)) {
        throw "Empty 'jwk' in supplied Header."
    }
    if ('kid' -in $Header.Keys -and [string]::IsNullOrWhiteSpace($Header.kid)) {
        throw "Empty 'kid' in supplied Header."
    }
    if ('nonce' -notin $Header.Keys -or [string]::IsNullOrWhiteSpace($Header.nonce)) {
        throw "Missing or empty 'nonce' in supplied Header."
    }
    if ('url' -notin $Header.Keys -or [string]::IsNullOrWhiteSpace($Header.url)) {
        throw "Missing or empty 'url' in supplied Header."
    }

    # build the "<protected>.<payload>" string we're going to be signing
    Write-Verbose "Header: $($Header | ConvertTo-Json)"
    $HeaderB64 = ConvertTo-Base64Url ($Header | ConvertTo-Json -Compress)
    Write-Verbose "Payload: $PayloadJson"
    $PayloadB64 = ConvertTo-Base64Url $PayloadJson
    $Message = "$HeaderB64.$PayloadB64"
    $MessageBytes = [Text.Encoding]::ASCII.GetBytes($Message)

    switch ($PSCmdlet.ParameterSetName) {
        'RSAKey' {
            # Make sure header 'alg' matches key type: RSAKey = RS256, ECKey = ES256
            if ($Header.alg -ne 'RS256') {
                throw "Supplied key object does not match 'alg' in supplied Header."
            }

            # create the signature
            $HashAlgo = [Security.Cryptography.HashAlgorithmName]::SHA256
            $PaddingType = [Security.Cryptography.RSASignaturePadding]::Pkcs1
            $SignedBytes = $RSAKey.SignData($MessageBytes, $HashAlgo, $PaddingType)
            break;
        }
        'ECKey' {
            # Make sure header 'alg' matches key type: RSAKey = RS256, ECKey = ES256
            if ($Header.alg -ne 'ES256') {
                throw "Supplied key object does not match 'alg' in supplied Header."
            }

            # create the signature
            $SignedBytes = $ECKey.SignData($MessageBytes)
            break;
        }
        default { throw "Unsupported key type" }
    }

    # now put everything together into the final JWS format
    $jws = [ordered]@{}
    $jws.payload = $PayloadB64
    $jws.protected = $HeaderB64
    $jws.signature = ConvertTo-Base64Url $SignedBytes

    # and return it
    Write-Verbose ($jws | ConvertTo-Json)
    return ($jws | ConvertTo-Json -Compress)

}
