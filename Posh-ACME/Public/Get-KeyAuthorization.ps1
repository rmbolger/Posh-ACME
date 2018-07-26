function Get-KeyAuthorization {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string]$Token,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    # https://tools.ietf.org/html/draft-ietf-acme-acme-12#section-8.1

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

    Begin {
        # make sure any account passed in is actually associated with the current server
        # or if no account was specified, that there's a current account.
        if (!$Account) {
            if (!($Account = Get-PAAccount)) {
                throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
            }
        } else {
            if ($Account.id -notin (Get-PAAccount -List).id) {
                throw "Specified account id $($Account.id) was not found in the current server's account list."
            }
        }
        # make sure it's valid
        if ($Account.status -ne 'valid') {
            throw "Account status is $($Account.status)."
        }

        # hydrate the account key
        $acctKey = $Account.key | ConvertFrom-Jwk

        # create the key thumbprint
        $pubJwk = $acctKey | ConvertTo-Jwk -PublicOnly -AsJson
        $jwkBytes = [Text.Encoding]::UTF8.GetBytes($pubJwk)
        $sha256 = [Security.Cryptography.SHA256]::Create()
        $jwkHash = $sha256.ComputeHash($jwkBytes)
        $thumb = ConvertTo-Base64Url $jwkHash
    }

    Process {
        # append the thumbprint to the token to make the key authorization
        return "$Token.$thumb"
    }




    <#
    .SYNOPSIS
        Calculate a key authorization string for a challenge token.

    .DESCRIPTION
        A key authorization is a string that expresses a domain holder's authorization for a specified key to satisfy a specified challenge, by concatenating the token for the challenge with a key fingerprint.

    .PARAMETER Token
        The token string for an ACME challenge.

    .PARAMETER Account
        The ACME account associated with the challenge.

    .EXAMPLE
        Get-KeyAuthorization 'XxXxXxXxXxXx'

        Get the key authorization for the specified token using the current account.

    .EXAMPLE
        (Get-PAOrder | Get-PAAuthorizations).DNS01Token | Get-KeyAuthorization

        Get all key authorizations for the DNS challenges in the current order using the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAuthorizations

    .LINK
        Submit-ChallengeValidation

    #>
}
