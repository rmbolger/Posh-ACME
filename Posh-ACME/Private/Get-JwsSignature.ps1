function Get-JwsSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [AllowEmptyString()]
        [string]$Message,
        [Parameter(Position=1)]
        [ValidateSet('RS256')]
        [Alias('algorithm')]
        [string]$JwsAlgorithm='RS256',
        [object]$Key
    )

    Process {

        # Per https://tools.ietf.org/html/rfc7518#section-3.1, both RS256 and ES256 are
        # recommended algorithms for Jws. We eventually want to support both. But we'll
        # start with RS256 and code as if there were multiple.
        
        # For our purposes, the "required" HS256 is actually banned for use
        # with ACME v2 as it is a MAC-based algorithm.
        # https://tools.ietf.org/html/draft-ietf-acme-acme-09#section-6.2

        switch ($JwsAlgorithm) {
            'RS256' {

                if ($Key) {
                    # validate the key type
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
                throw "Unsupported JwsAlgorithm"
            }
            default { throw "Unsupported JwsAlgorithm" }
        }

        # Send the encoded signature back
        return (ConvertTo-Base64Url $SignedBytes)

    }
}