function New-Jwk {
    [CmdletBinding()]
    param(
        [ValidateSet('RSA','EC')]
        [Alias('type','kty')]
        [string]$KeyType='RSA',
        [Alias('size')]
        [int]$KeySize=2048
    )

    # 'kty' is case-sensitive
    # https://tools.ietf.org/html/rfc7517#section-4.1
    $KeyType = $KeyType.ToUpper()

    # For EC keys, the KeySize parameter is going to dictate the curve used,
    # so validate that they passed a supported one or default to 256.
    $ECSupported = 256,384,521
    if ($KeyType -eq 'EC') {
        if (!$PSBoundParameters.ContainsKey('KeySize')) {
            $KeySize = 256
        } elseif ($KeySize -notin $ECSupported) {
            throw "Unsupported EC KeySize. Try 256, 384, or 521."
        }
    }

    # For RSA keys, Windows supports a huge range of key sizes. But LE's current Boulder server only supports
    # between 2048-4096 keys. So we'll limit to that until someone complains.
    # https://msdn.microsoft.com/en-us/library/system.security.cryptography.rsacryptoserviceprovider.keysize(v=vs.110).aspx
    if ($KeyType -eq 'RSA' -and ($KeySize -lt 2048 -or $KeySize -gt 4096 -or ($KeySize % 128) -ne 0)) {
        throw "Unsupported RSA KeySize. Try between 2048-4096."
    }

    # create the new key
    switch ($KeyType) {
        'RSA' {
            $key = New-Object Security.Cryptography.RSACryptoServiceProvider $KeySize
            $keyParams = $Key.ExportParameters($true)

            # put the pieces into an alpha ordered hashtable
            $keyHT = [ordered]@{
                d = (ConvertTo-Base64Url $keyParams.D);
                dp = (ConvertTo-Base64Url $keyParams.DP);
                dq = (ConvertTo-Base64Url $keyParams.DQ);
                e = (ConvertTo-Base64Url $keyParams.Exponent);
                kty = 'RSA';
                n = (ConvertTo-Base64Url $keyParams.Modulus);
                p = (ConvertTo-Base64Url $keyParams.P);
                q = (ConvertTo-Base64Url $keyParams.Q);
                qi = (ConvertTo-Base64Url $keyParams.InverseQ);
            }
            break;
        }
        'EC' {
            # Use Curves created via OID because CreateFromFriendlyName wasn't working very well
            # cross-platform.
            # https://msdn.microsoft.com/en-us/library/windows/desktop/mt632245(v=vs.85).aspx
            switch ($KeySize) {
                256 {
                    # nistP256 / secP256r1 / x962P256v1
                    $Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7')
                    $crv = 'P-256'
                    break;
                }
                384 {
                    # secP384r1
                    $Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.34')
                    $crv = 'P-384'
                    break;
                }
                521 {
                    # secP521r1
                    $Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.35')
                    $crv = 'P-521'
                    break;
                }
                default { throw "Unsupported EC KeySize. Try 256, 384, or 521." }
            }
            $Key = [Security.Cryptography.ECDsa]::Create($Curve)
            $KeyParams = $Key.ExportParameters($true)

            # put the pieces into an alpha ordered hashtable
            $keyHT = [ordered]@{
                crv = $crv;
                d = (ConvertTo-Base64Url $keyParams.D);
                kty = 'EC';
                x = (ConvertTo-Base64Url $keyParams.Q.X);
                y = (ConvertTo-Base64Url $keyParams.Q.Y);
            }
            break;
        }
        default { throw "Unsupported KeyType parameter" }
    }

    Write-Output ($keyHT | ConvertTo-Json -Compress)
}

