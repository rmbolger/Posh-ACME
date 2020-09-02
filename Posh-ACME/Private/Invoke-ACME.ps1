function Invoke-ACME {
    [CmdletBinding(DefaultParameterSetName='Account')]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$Header,
        [Parameter(Mandatory,Position=1)]
        [AllowEmptyString()]
        [string]$PayloadJson,
        [Parameter(ParameterSetName='Account',Mandatory,Position=2)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(ParameterSetName='RawKey',Mandatory,Position=2)]
        [ValidateScript({Test-ValidKey $_ -ThrowOnFail})]
        [Security.Cryptography.AsymmetricAlgorithm]$Key,
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

    # set the account key based on the parameter set
    if ($PSCmdlet.ParameterSetName -eq 'Account') {
        # hydrate the account key
        $acctKey = $Account.key | ConvertFrom-Jwk
    } else {
        # use the one passed in
        $acctKey = $Key
    }

    # Validation on the rest of the header will be taken care of by New-Jws. And
    # the only reason we aren't just simplifying by changing the input param to a
    # completed JWS string is because we want to be able to auto-retry on errors
    # like badNonce which requires modifying the Header and re-signing a new JWS.
    $Jws = New-Jws $acctKey $Header $PayloadJson

    # since HTTP error codes make Invoke-WebRequest throw an exception,
    # we need to wrap it in a try/catch. But we can still get the response
    # object via the exception.

    try {
        $iwrSplat = @{
            Uri = $Header.url
            Body = $Jws
            Method = 'Post'
            ContentType = 'application/jose+json'
            UserAgent = $script:USER_AGENT
            Headers = $script:COMMON_HEADERS
            ErrorAction = 'Stop'
        }

        $response = Invoke-WebRequest @iwrSplat @script:UseBasic

        # update the next nonce if it was sent
        if ($response -and $response.Headers.ContainsKey($script:HEADER_NONCE)) {
            $script:Dir.nonce = $response.Headers[$script:HEADER_NONCE] | Select-Object -First 1
            Write-Debug "Updating nonce: $($script:Dir.nonce)"
        }

        return $response

    } catch {
        # Since we can't catch explicit exception types between PowerShell editions
        # without errors for non-existent types, we need to string match the type names
        # and re-throw anything we don't care about.
        $exType = $_.Exception.GetType().FullName
        if ('System.Net.WebException' -eq $exType) {

            # This is the exception that gets thrown in PowerShell Desktop edition

            # get the response object: System.Net.HttpWebResponse
            $ex = $_.Exception
            $response = $ex.Response

            # update the next nonce if it was sent
            if ($script:HEADER_NONCE -in $response.Headers) {
                $script:Dir.nonce = $response.GetResponseHeader($script:HEADER_NONCE) | Select-Object -First 1
                Write-Debug "Updating nonce from error response: $($script:Dir.nonce)"
                $freshNonce = $true
            }

            # grab the raw response body
            $sr = New-Object IO.StreamReader($response.GetResponseStream())
            $sr.BaseStream.Position = 0
            $sr.DiscardBufferedData()
            $body = $sr.ReadToEnd()
            Write-Debug "Error Body: $body"

        } elseif ('Microsoft.PowerShell.Commands.HttpResponseException' -eq $exType) {

            # This is the exception that gets thrown in PowerShell Core edition

            # get the response object
            # Linux type: System.Net.Http.CurlHandler+CurlResponseMessage
            #   Mac type: ???
            #   Win type: System.Net.Http.HttpResponseMessage
            $ex = $_.Exception
            $response = $ex.Response

            # update the next nonce if it was sent
            if ($script:HEADER_NONCE -in $response.Headers.Key) {
                $script:Dir.nonce = ($response.Headers | Where-Object { $_.Key -eq $script:HEADER_NONCE }).Value | Select-Object -First 1
                Write-Debug "Updating nonce from error response: $($script:Dir.nonce)"
                $freshNonce = $true
            }

            # Currently in PowerShell 6, there's no way to get the raw response body from an
            # HttpResponseException because they dispose the response stream.
            # https://github.com/PowerShell/PowerShell/issues/5555
            # https://get-powershellblog.blogspot.com/2017/11/powershell-core-web-cmdlets-in-depth.html
            # However, a "processed" version of the body is available via ErrorDetails.Message
            # which *should* work for us. The processing they're doing should only be removing HTML
            # tags. And since our body should be JSON, there shouldn't be any tags to remove.
            # So we'll just go with it for now until someone reports a problem.
            $body = $_.ErrorDetails.Message
            Write-Debug "Error Body: $body"

        } else { throw }

        # ACME uses RFC7807, Problem Details for HTTP APIs
        # https://tools.ietf.org/html/rfc7807
        # So a JSON parseable error object should be in the response body.
        try { $acmeError = $body | ConvertFrom-Json }
        catch {
            # Old endpoints won't necessarily throw rfc7807 bodies
            # for 404 errors. So we're going to fake them.
            # https://github.com/letsencrypt/boulder/issues/4540
            if (404 -eq $response.StatusCode) {
                $acmeError = @{
                    type = 'urn:ietf:params:acme:error:malformed'
                    detail = 'Page not found'
                    status = 404
                }
            } else {
                Write-Warning "Response body was not JSON parseable"
                # re-throw the original exception
                throw $ex
            }
        }

        # check for badNonce and retry once
        if (!$NoRetry -and $freshNonce -and $acmeError.type -and $acmeError.type -like '*:badNonce') {
            $Header.nonce = $script:Dir.nonce
            Write-Verbose "Nonce rejected by ACME server. Retrying with updated nonce."
            return (Invoke-ACME $Header $PayloadJson -Key $acctKey -NoRetry)
        }

        # throw the converted AcmeException
        throw [AcmeException]::new($acmeError.detail,$acmeError)
    }





    <#
    .SYNOPSIS
        Send an authenticated ACME protocol message.

    .DESCRIPTION
        This is an advanced function used to send custom commands to an ACME server. You must provide a proper header hashtable and JSON body. Then the function will sign the data with an account or raw key and send it.

    .PARAMETER Header
        A hashtable containing the appropriate fields for an ACME message header such as 'alg', 'jwk', 'kid', 'nonce', and 'url'. The url field is also used as the destination for the message.

    .PARAMETER PayloadJson
        A JSON formatted string with the ACME message body.

    .PARAMETER Account
        An existing ACME account object such as the output from Get-PAAccount.

    .PARAMETER Key
        A raw RSA or EC key object. This is usually only necessary when creating a new ACME account.

    .PARAMETER NoRetry
        If specified, don't retry on bad nonce errors. Occasionally, the nonce provided in an ACME message will be rejected. By default, this function requests a new nonce once and tries to send the message again before giving up.

    .EXAMPLE
        $acct = Get-PAAccount
        PS C:\>$header = @{ alg=$acct.alg; kid=$acct.location; nonce='xxxxxxxxxxxxxx'; url='https://acme.example.com/acme/challenge/xxxxxxxxxxxxx' }
        PS C:\>$payloadJson = '{}'
        PS C:\>Invoke-ACME $header $payloadJson $acct

        Send an ACME message using the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    #>
}
