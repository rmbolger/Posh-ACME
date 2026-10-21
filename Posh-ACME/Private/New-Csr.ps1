function New-Csr {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAOrder')]$Order
    )

    # Make sure we have an account configured
    if (-not (Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
    }

    # Order verification should have already been taken care of
    $keyFile = Join-Path $Order.Folder 'cert.key'
    $reqFile = Join-Path $Order.Folder 'request.csr'
    $keyExists = Test-Path $keyFile -PathType Leaf
    $keyPem = if ($keyExists) { Get-Content $keyFile -Raw } else { $null }

    # super lazy IPv4 address regex, but we just need to be able to
    # distinguish from an FQDN
    $reIPv4 = [regex]'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'

    # create the subject
    if ($Order.Subject) {
        # use the specified subject
        $subject = $Order.Subject
    } elseif ($Order.MainDomain.Length -le 64 -and
              $Order.MainDomain -notmatch $reIPv4 -and
              $Order.MainDomain -notlike '*:*'
    ) {
        # use the main domain as the subject as long as it's
        # not an IP address or IPv6 address and within the length limit
        $subject = "CN=$($Order.MainDomain)"
    } else {
        # fallback to an empty subject if no suitable subject can be determined
        $subject = [string]::Empty
    }

    # pass the request to the crypto helper to generate the CSR
    $csrParams = @{
        KeyLength = $Order.KeyLength
        Subject = $subject
        Identifiers = @($Order.identifiers)
        OCSPMustStaple = [bool]$Order.OCSPMustStaple
        PrivateKeyPem = $keyPem
    }
    $csrResult = New-CsrHelper @csrParams

    # write the private key to a file if it was newly created
    if (-not $keyExists -and $csrResult.PrivateKeyPem) {
        $keyPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($keyFile)
        [IO.File]::WriteAllText($keyPath, $csrResult.PrivateKeyPem, [Text.Encoding]::ASCII)
    }

    # export the csr to a file
    $requestPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($reqFile)
    [IO.File]::WriteAllText($requestPath, $csrResult.RequestPem, [Text.Encoding]::ASCII)

    # return the CSR as Base64Url
    return $csrResult.Base64Url
}
