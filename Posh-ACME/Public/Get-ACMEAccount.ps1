function Get-ACMEAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({Test-ValidKey $_ -ThrowOnFail})]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
        [Parameter(Position=1)]
        [string[]]$Contact,
        [switch]$AcceptTOS,
        [switch]$NoCreate
    )

    # Determine the proper 'alg' from the key based on
    # https://tools.ietf.org/html/rfc7518
    # and what we know LetsEncrypt supports today which includes
    # RS256 for all RSA keys
    # ES256 for P-256 keys
    # ES384 for P-384 keys
    # ES512 for P-521 keys (not a typo, 521 is the curve, 512 is the SHA512 hash algorithm)
    if ($Key -is [Security.Cryptography.RSA]) {
        $alg = 'RS256'
    } else {
        # key must be EC due to earlier validation
        if ($Key.KeySize -eq 256) {
            $alg = 'ES256'
        } elseif ($Key.KeySize -eq 384) {
            $alg = 'ES384'
        } elseif ($Key.KeySize -eq 521) {
            $alg = 'ES512'
        } else {
            # this means the validation script broken or wer'e out of date
            throw "Unsupported EC curve."
        }
    }

    # build the protected header for the request
    $header = @{
        alg   = $alg;
        jwk   = ($Key | ConvertTo-Jwk -PublicOnly);
        nonce = $script:NextNonce;
        url   = $script:dir.newAccount;
    }

    # build the payload
    $payload = @{}

    # make sure the Contact emails have a "mailto:" prefix
    # this may get more complex later if ACME server support more than email based contacts
    if ($Contact.Count -gt 0) {
        0..($Contact.Count-1) | %{
            if ($Contact[$_] -notlike 'mailto:*') {
                $Contact[$_] = "mailto:$($Contact[$_])"
            }
        }

        $payload.contact = $Contact
    }
    if ($AcceptTOS) {
        $payload.termsOfServiceAgreed = $true
    }
    if ($NoCreate) {
        $payload.onlyReturnExisting = $true
    }
    $payloadJson = $payload | ConvertTo-Json -Compress

    # send the request
    $response = Invoke-ACME $script:dir.newAccount $Key $header $payloadJson -EA Stop

    if ($response.Headers.ContainsKey('Location')) {
        Write-Host "Location: $($response.Headers['Location'])"
    }
    Write-Host ($response.Content)

}