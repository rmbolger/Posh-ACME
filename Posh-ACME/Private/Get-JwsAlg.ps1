function Get-JwsAlg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({Test-ValidKey $_ -ThrowOnFail})]
        [Security.Cryptography.AsymmetricAlgorithm]$Key
    )

    # Determine the proper 'alg' from the key based on
    # https://tools.ietf.org/html/rfc7518
    # and what we know LetsEncrypt supports today which includes
    # RS256 for all RSA keys
    # ES256 for P-256 keys
    # ES384 for P-384 keys
    # ES512 for P-521 keys (not a typo, 521 is the curve, 512 is the SHA512 hash algorithm)
    if ($Key -is [Security.Cryptography.RSA]) {
        return 'RS256'
    } else {
        # key must be EC due to earlier validation
        if ($Key.KeySize -eq 256) {
            return 'ES256'
        } elseif ($Key.KeySize -eq 384) {
            return 'ES384'
        } elseif ($Key.KeySize -eq 521) {
            return 'ES512'
        } else {
            # this means the validation script broke or we're out of date
            throw "Unsupported EC curve."
        }
    }

}