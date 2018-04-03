function Get-KeyAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=1)]
        [string]$Token
    )

    # https://tools.ietf.org/html/draft-ietf-acme-acme-10#section-8.1

    # A key authorization is a string that expresses
    # a domain holder's authorization for a specified key to satisfy a
    # specified challenge, by concatenating the token for the challenge
    # with a key fingerprint, separated by a "." character:

    # keyAuthorization = token || '.' || base64url(JWK_Thumbprint(accountKey))

    # The "JWK_Thumbprint" step indicates the computation specified in
    # [RFC7638], using the SHA-256 digest [FIPS180-4].  As noted in
    # [RFC7518] any prepended zero octets in the fields of a JWK object
    # MUST be stripped before doing the computation.

    # As specified in the individual challenges below, the token for a
    # challenge is a string comprised entirely of characters in the URL-
    # safe base64 alphabet.  The "||" operator indicates concatenation of
    # strings.

    # hydrate the key
    $key = $Account.key | ConvertFrom-Jwk

    # create the key thumbprint
    $pubJwk = $key | ConvertTo-Jwk -PublicOnly -AsJson
    $jwkBytes = [Text.Encoding]::UTF8.GetBytes($pubJwk)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $jwkHash = $sha256.ComputeHash($jwkBytes)
    $thumb = ConvertTo-Base64Url $jwkHash

    # append it to the token to make the key authorization
    $keyAuth = "$Token.$thumb"

    return $keyAuth
}