function Revoke-PACertificate {
    [CmdletBinding()]
    [OutputType('PoshACME.PACertificate')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='MainDomain',Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='CertPEM',Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$CertPEM,
        [Parameter(ParameterSetName='MainDomain')]
        [Parameter(ParameterSetName='CertPEM')]
        [int]$Reason
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        if ($PSCmdlet.ParameterSetName -eq 'MainDomain') {
            $PACertificate = Get-PACertificate -MainDomain $MainDomain
            if (!$PACertificate) {
                throw "No certificate with that name."
            }

            $certFile = $PACertificate.CertFile
            $cert = Import-Pem -InputFile $certFile
        } else {
            $cert = Import-Pem -InputString $CertPEM

            # Pull the main domain out of the certificate
            $MainDomain = $cert.SubjectDN
            if (!$MainDomain -imatch "^CN=") {
                throw "Could not extract main domain from certificate."
            } else {
                $MainDomain = $MainDomain -ireplace "^CN=", ""
            }
        }

        $base64 = ConvertTo-Base64Url $cert.GetEncoded()

        # build the protected header for the request
        $header = @{
            alg   = $acct.alg;
            kid   = $acct.location;
            nonce = $script:Dir.nonce;
            url   = $script:Dir.revokeCert;
        }

        # build the payload
        $payload = @{certificate=$base64}
        if ($Reason -and $Reason -ge 1 -and $Reason -le 5) {
            $payload.reason = $Reason
        }

        $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

        # send the request
        try {
            $response = Invoke-ACME $header $payloadJson $acct -EA Stop
        } catch { throw }

        Update-PAOrder $MainDomain
    }

    <#
    .SYNOPSIS
        Revoke an ACME certificate

    .DESCRIPTION
        Revokes a previously created ACME certificate.

    .PARAMETER MainDomain
        The primary domain associated with the certificate to be revoked. This is the domain that goes in the certificate's subject. Provide this argument if not providing CertPEM.

    .PARAMETER CertPEM
        The PEM-encoded certificate to be revoked. Provide this argument if not providing MainDomain.

    .PARAMETER Reason
        An optional reason for the revocation, one of 1 (User Key Compromised), 2 (CA Key Compromised), 3 (User Changed Affiliation), 4 (Certificate Superseded), 5 (Original Use No Longer Valid)

    .EXAMPLE
        Revoke-PACertificate site.example.com

        Revokes the certificate for the specified domain.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    #>
}
