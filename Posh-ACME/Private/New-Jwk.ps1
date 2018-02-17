function New-Jwk {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateScript({Test-ValidKeyLength $_})]
        [string]$KeyLength='2048',
        [switch]$AsJson,
        [switch]$AsPrettyJson
    )

    # RFC Note: 'kty' is case-sensitive
    # https://tools.ietf.org/html/rfc7517#section-4.1

    # KeyLength should have already been validated which means it should be a parseable
    # [int] that may have an "ec-" prefix
    if ($KeyLength -like 'ec-*') {
        $KeyType = 'EC'
        $KeySize = [int]::Parse($KeyLength.Substring(3))
    } else {
        $KeyType = 'RSA'
        $KeySize = [int]::Parse($KeyLength)
    }

    # create the new key
    switch ($KeyType) {
        'RSA' {
            $Key = New-Object Security.Cryptography.RSACryptoServiceProvider $KeySize
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
                    break;
                }
                384 {
                    # secP384r1
                    $Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.34')
                    break;
                }
                521 {
                    # secP521r1
                    $Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.35')
                    break;
                }
                default { throw "Unsupported EC KeySize. Try 256, 384, or 521." }
            }
            $Key = [Security.Cryptography.ECDsa]::Create($Curve)
            break;
        }
        default { throw "Unsupported KeyType parameter" }
    }

    if ($AsPrettyJson) {
        return ($Key | ConvertTo-Jwk -AsPrettyJson)
    } elseif ($AsJson) {
        return ($Key | ConvertTo-Jwk -AsJson)
    } else {
        return ($Key | ConvertTo-Jwk)
    }
}

