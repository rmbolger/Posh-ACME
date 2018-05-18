function Invoke-ACME {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [Parameter(Mandatory)]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
        [Parameter(Mandatory)]
        [hashtable]$Header,
        [Parameter(Mandatory)]
        [string]$PayloadJson,
        [switch]$NoRetry
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # Because we're not refreshing the server on module load, we may not have a
    # NextNonce set yet. So check the header, and grab a fresh one if it's empty.
    if ([string]::IsNullOrWhiteSpace($Header.nonce)) {
        $Header.nonce = Get-Nonce
    }

    # Validation on the rest of the header will be taken care of by New-Jws. And
    # the only reason we aren't just simplifying by changing the input param to a
    # completed JWS string is because we want to be able to auto-retry on errors
    # like badNonce which requires modifying the Header and re-signing a new JWS.
    $Jws = New-Jws $Key $Header $PayloadJson

    # since HTTP error codes make Invoke-WebRequest throw an exception,
    # we need to wrap it in a try/catch. But we can still get the response
    # object via the exception.
    try {
        $response = Invoke-WebRequest -Uri $Uri -Body $Jws -Method Post `
            -ContentType 'application/jose+json' -UserAgent $script:USER_AGENT `
            -Headers $script:COMMON_HEADERS -EA Stop @script:UseBasic

        # update the next nonce if it was sent
        if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
            Write-Debug "Updating nonce: $($response.Headers[$script:HEADER_NONCE])"
            $script:Dir.nonce = $response.Headers[$script:HEADER_NONCE]
        }

        return $response

    } catch [Net.WebException] {

        $ex = $_.Exception
        $response = $ex.Response

        # update the next nonce if it was sent
        if ($script:HEADER_NONCE -in $response.Headers) {
            Write-Debug "Updating nonce from error response: $($response.Headers[$script:HEADER_NONCE])"
            $script:Dir.nonce = $response.GetResponseHeader($script:HEADER_NONCE)
            $freshNonce = $true
        }

        # ACME uses RFC7807, Problem Details for HTTP APIs
        # https://tools.ietf.org/html/rfc7807
        # So a JSON parseable error object should be in the response body.
        # We just have to pull it out and parse it.

        $sr = New-Object IO.StreamReader($response.GetResponseStream())
        $sr.BaseStream.Position = 0
        $sr.DiscardBufferedData()
        $body = $sr.ReadToEnd()
        Write-Debug "Error Body: $body"

        # try parsing the body
        try { $acmeError = $body | ConvertFrom-Json }
        catch {
            Write-Warning "Response body was not JSON parseable"
            # re-throw the original exception
            throw $ex
        }

        # check for badNonce and retry once
        if (!$NoRetry -and $freshNonce -and $acmeError.type -and $acmeError.type -like '*:badNonce') {
            $Header.nonce = $script:Dir.nonce
            Write-Debug "Retrying with updated nonce"
            return (Invoke-ACME $Uri $Key $Header $PayloadJson -NoRetry)
        }

        # throw the converted AcmeException
        throw [AcmeException]::new($acmeError.detail,$acmeError)
    }

}
