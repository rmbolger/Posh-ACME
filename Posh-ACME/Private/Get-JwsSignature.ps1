function Get-JwsSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [AllowEmptyString()]
        [string]$Message,
        [Parameter(Position=1)]
        [ValidateSet('RS256','ES256')]
        [Alias('algorithm')]
        [string]$JwsAlgorithm='RS256',
        [object]$Key
    )

    Process {

        # Per https://tools.ietf.org/html/rfc7518#section-3.1, both RS256 and ES256 are
        # recommended algorithms for Jws and HS256 is "required". However, HS256 is called
        # out in the ACME v2 RFC as banned for use because it's MAC based..
        # https://tools.ietf.org/html/draft-ietf-acme-acme-09#section-6.2

        switch ($JwsAlgorithm) {
            'RS256' {

                if ($Key) {
                    # validate the key type
                    # RSASSA-PKCS1-v1_5 using SHA-256
                    if ($Key -isnot [Security.Cryptography.RSA]) {
                        throw "Key parameter type doesn't match the JwsAlgorithm"
                    }
                } else {
                    # generate a new key
                    $Key = New-Object Security.Cryptography.RSACryptoServiceProvider 4096
                }

                # sign the message
                $MessageBytes = [Text.Encoding]::ASCII.GetBytes($Message)
                $HashAlgo = [Security.Cryptography.HashAlgorithmName]::SHA256
                $PaddingType = [Security.Cryptography.RSASignaturePadding]::Pkcs1
                $SignedBytes = $Key.SignData($MessageBytes, $HashAlgo, $PaddingType)

                break;
            }
            'ES256' {

                if ($Key) {
                    # validate the key type
                    # ECDSA using P-256 and SHA-256
                    if ($Key -isnot [Security.Cryptography.ECDsa]) {
                        throw "Key parameter type doesn't match the JwsAlgorithm"
                    }
                } else {
                    # generate a new random key
                    $Curve = [Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7')
                    $Key = [Security.Cryptography.ECDsa]::Create($Curve)
                }

                # sign the message
                $MessageBytes = [Text.Encoding]::ASCII.GetBytes($Message)
                $SignedBytes = $Key.SignData($MessageBytes)

                break;
            }
            default { throw "Unsupported JwsAlgorithm" }
        }

        # Send the encoded signature back
        return (ConvertTo-Base64Url $SignedBytes)

    }
}