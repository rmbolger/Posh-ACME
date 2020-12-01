function New-Jws {
    [CmdletBinding(DefaultParameterSetName='Asymmetric')]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory, ParameterSetName='Asymmetric', Position=0)]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
        [Parameter(Mandatory, ParameterSetName='HMAC', Position=0)]
        [Security.Cryptography.HMAC]$HMAC,
        [Parameter(Mandatory, Position=1)]
        [System.Collections.IDictionary]$Header,
        [Parameter(Mandatory, Position=2)]
        [AllowEmptyString()]
        [string]$PayloadJson,
        [switch]$Compact,
        [switch]$NoHeaderValidation
    )

    # RFC 7515 - JSON Web Signature (JWS)
    # https://tools.ietf.org/html/rfc7515
    # https://tools.ietf.org/html/rfc7518#section-3.1

    # This is not a general JWS implementation. It will specifically
    # cater to making JWS messages for the ACME v2 protocol.
    # https://tools.ietf.org/html/rfc8555

    if ('Asymmetric' -eq $PSCmdlet.ParameterSetName) {

        # validate the key type
        if ($Key -is [Security.Cryptography.RSA]) {

            # validate the key size
            # LE supports 2048-4096
            # Windows claims to support 8-bit increments (mod 128)
            if ($Key.KeySize -lt 2048 -or $Key.KeySize -gt 4096 -or ($Key.KeySize % 128) -ne 0) {
                throw "Unsupported RSA key size. Must be 2048-4096 in 8 bit increments."
            }

            # make sure we have a private key to sign with
            if ($Key.PublicOnly) {
                throw "Supplied Key has no private key portion."
            }

        } elseif ($Key -is [Security.Cryptography.ECDsa]) {

            # validate the curve size which is exposed via KeySize
            if ($Key.KeySize -notin 256,384,521) {
                throw "Unsupported EC curve. Must be P-256, P-384, or P-521"
            }

            # make sure we have a private key to sign with
            # since there's no PublicOnly property, we have to fake it by trying to export
            # the private parameters and catching the error
            try { $Key.ExportParameters($true) | Out-Null }
            catch { throw "Supplied Key has no private key portion." }

        } else {
            throw "Unsupported Key type. Must be RSA or ECDsa"
        }

        # validate the headers
        if (-not $NoHeaderValidation) {

            if ('alg' -notin $Header.Keys -or $Header.alg -notin 'RS256','ES256','ES384','ES512') {
                throw "Missing or invalid 'alg' in supplied Header"
            }

            # Make sure header 'alg' matches key type.
            if ($Key -and $Key -is [Security.Cryptography.RSA] -and $Header.alg -ne 'RS256') {
                throw "Supplied RSA Key does not match 'alg' ($($Header.alg)) in supplied Header."
            }

            # Make sure header 'alg' matches key type. EC keys depend on the curve
            # ES256 = P-256 and SHA256 hash
            # ES384 = P-384 and SHA384 hash
            # ES512 = P-521 and SHA512 hash (note 521 vs 512, very confusing)
            if ($Key -and $Key -is [Security.Cryptography.ECDsa] -and
                ($Header.alg -notin 'ES256','ES384','ES512' -or
                ($Header.alg -eq 'ES256' -and $Key.KeySize -ne 256) -or
                ($Header.alg -eq 'ES384' -and $Key.KeySize -ne 384) -or
                ($Header.alg -eq 'ES512' -and $Key.KeySize -ne 521))
            ) {
                throw "Supplied EC Key (P-$($Key.KeySize)) does not match 'alg' ($($Header.alg)) in supplied header or alg is not supported."
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
        }
    }

    # build the "<protected>.<payload>" string we're going to be signing
    Write-Debug "ACME Header: `n$($Header | ConvertTo-Json -Depth 5)"
    $HeaderB64 = ConvertTo-Base64Url ($Header | ConvertTo-Json -Depth 5 -Compress)
    if ($PayloadJson -eq [String]::Empty) {
        Write-Debug "ACME Payload: (empty)"
    } else {
        Write-Debug "ACME Payload: `n$PayloadJson"
    }
    $PayloadB64 = ConvertTo-Base64Url $PayloadJson
    $Message = "$HeaderB64.$PayloadB64"
    $MessageBytes = [Text.Encoding]::ASCII.GetBytes($Message)

    if ($Key -and $Key -is [Security.Cryptography.RSA]) {

        # create the signature
        $HashAlgo = [Security.Cryptography.HashAlgorithmName]::SHA256
        $PaddingType = [Security.Cryptography.RSASignaturePadding]::Pkcs1
        Write-Debug "Signing message using RSA with $HashAlgo"
        $SignedBytes = $Key.SignData($MessageBytes, $HashAlgo, $PaddingType)

    }
    elseif ($Key -and $Key -is [Security.Cryptography.ECDsa]) {

        $HashAlgo = switch ($Key.KeySize) {
            256 { [Security.Cryptography.HashAlgorithmName]::SHA256; break }
            384 { [Security.Cryptography.HashAlgorithmName]::SHA384; break }
            521 { [Security.Cryptography.HashAlgorithmName]::SHA512; break }
        }

        # create the signature
        Write-Debug "Signing message using EC with $HashAlgo"
        $SignedBytes = $Key.SignData($MessageBytes, $HashAlgo)
    }
    else {
        # we must be using the passed in HMAC

        # Make sure the header 'alg' matches the hmac type.
        if (-not $NoHeaderValidation -and $HMAC -and
            ($Header.alg -notin 'HS256','HS384','HS512' -or
            ($Header.alg -eq 'HS256' -and $HMAC.HashSize -ne 256) -or
            ($Header.alg -eq 'HS384' -and $HMAC.HashSize -ne 384) -or
            ($Header.alg -eq 'HS512' -and $HMAC.HashSize -ne 512))
        ) {
            throw "Supplied HMAC object (HashSize $($HMAC.HashSize) does not match 'alg' ($($Header.alg)) in the supplied header or alg is not supported."
        }

        # create the signature
        Write-Debug "Signing message using HMAC with hash size $($HMAC.HashSize)"
        $SignedBytes = $HMAC.ComputeHash($MessageBytes)
    }

    # now put everything together into the final JWS format
    if ($Compact) {
        # JWS Compact Serialization
        # https://tools.ietf.org/html/rfc7515#section-3.1

        return "$HeaderB64.$PayloadB64.$(ConvertTo-Base64Url $SignedBytes)"

    } else {
        # JWS JSON Serialization
        # https://tools.ietf.org/html/rfc7515#section-3.2

        $jws = [ordered]@{}
        $jws.payload = $PayloadB64
        $jws.protected = $HeaderB64
        $jws.signature = ConvertTo-Base64Url $SignedBytes

        # and return it
        return ($jws | ConvertTo-Json -Depth 5 -Compress)
    }

}
