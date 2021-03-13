function Get-Nonce {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('newNonce')]
        [string]$NewNonceUrl
    )

    # https://tools.ietf.org/html/rfc8555#section-7.2

    Process {

        # if there was no Url passed in, check if there's a saved one
        if (!$NewNonceUrl) {
            if (!$script:Dir -or !$script:Dir.newNonce) {
                throw "No NewNonceUrl passed in or saved on current PAServer."
            } else {
                $NewNonceUrl = $script:Dir.newNonce
            }
        }

        # make the request
        Write-Debug "Requesting nonce from $NewNonceUrl"
        try {
            $response = Invoke-WebRequest $NewNonceUrl -Method Head `
                -UserAgent $script:USER_AGENT -Headers $script:COMMON_HEADERS `
                -EA Stop -Verbose:$false @script:UseBasic
        } catch { throw }

        # return the value from the response
        if ($response.Headers.ContainsKey($script:HEADER_NONCE)) {
            return $response.Headers[$script:HEADER_NONCE] | Select-Object -First 1
        } else {
            throw "$($script:HEADER_NONCE) not found in response headers."
        }

    }
}
