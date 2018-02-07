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
        [string]$Payload
    )

    # RFC 7515 - JSON Web Signature (JWS)
    # https://tools.ietf.org/html/rfc7515

    # This is not a general JWS implementation. It will specifically
    # cater to making JWS messages for the ACME v2 protocol.
    # https://tools.ietf.org/html/draft-ietf-acme-acme-09

    # ACME messages should have either 'jwk' or 'kid' in the header.
    # It is assumed the caller has built the header properly for the call
    # being made.

    # Validate the header
    if ('alg' -notin $Header.Keys -or $Header.alg -notin 'RS256','EC256') {
        throw "Missing or invalid 'alg' in supplied Header"
    }
    if ('jwk' -in $Header.Keys -xor 'kid' -in $Header.Keys) {
        if ('jwk' -in $Header.Keys) {
            throw "Conflicting key entries. Both 'jwk' and 'kid' found in supplied Header"
        } else {
            throw "Missing key entries. Neither 'jwk' or 'kid' found in supplied Header"
        }
    }

    # Make sure header 'alg' matches key type
    # RSAKey should be RS256, ECKey should be EC256
    switch ($PSCmdlet.ParameterSetName) {
        'RSAKey' {

            break;
        }
        'ECKey' {
            break;
        }
        default { throw "Unsupported key type" }
    }





}
