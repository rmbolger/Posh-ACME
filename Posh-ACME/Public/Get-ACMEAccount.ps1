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

    # build the protected header for the request
    $header = @{
        alg   = (Get-JwsAlg $Key);
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
        return $response.Headers['Location']
    } else {
        #Write-Host ($response.Content)
        throw 'No Location header found in newAccount output'
    }

}