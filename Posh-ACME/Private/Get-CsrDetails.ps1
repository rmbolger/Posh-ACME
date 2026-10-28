function Get-CsrDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('CSRString')]
        [string]$CSRPath
    )

    # Given a PEM formatted CSR file path or raw string value, we need to parse the
    # request and return a hashtable with the following parsed details to the caller:
    #
    #   Domain    : The collection of FQDNs found in the CN and/or SAN attributes
    #   KeyLength : The key length value using our Posh-ACME nomeclature
    #   OCSPMustStaple : Boolean indicating whether the OCSP Must Staple flag is set
    #   Base64Url : The Base64Url encoded bytes of the raw request
    #   Pem       : The normalized PEM request content

    # Allow for CSRs being passed directly as a string value in addition to a
    # filesystem path. Anything missing the correct header string will be treated
    # as a file path.
    if ($CSRPath -cnotlike '*CERTIFICATE REQUEST*') {
        Write-Debug "CSRPath didn't match CERTIFICATE REQUEST"

        # normalize the CSR path and make sure it exists
        $CSRPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CSRPath)
        if (-not (Test-Path $CSRPath -PathType Leaf)) {
            throw "CSR file not found at $CSRPath"
        }

        $csrPem = Get-Content $CSRPath -Raw
        $pemLines = Get-Content $CSRPath
    } else {
        $csrPem = $CSRPath
        $pemLines = $CSRPath.Trim() -split "(?:`r)?`n"
    }
    $normalizedPem = ($pemLines -join "`n") + "`n"

    Write-Debug "Attempting to parse CSR pem"
    $csrDetails = Get-CsrDetail -Pem $csrPem
    # The helper won't throw on unsupported RSA KeyLengths, so we need to check manually.
    if ($csrDetails.KeyLength -notlike 'ec-*' -and -not (Test-ValidKeyLength $csrDetails.KeyLength)) {
        throw "RSA key length from CSR is out of the supported range. ($($csrDetails.KeyLength))"
    }

    return @{
        Domain = [string[]]@($csrDetails.Domain)
        KeyLength = $csrDetails.KeyLength
        OCSPMustStaple = $csrDetails.OCSPMustStaple
        Base64Url = $csrDetails.Base64Url
        Pem = $normalizedPem
    }
}
