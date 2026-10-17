function Get-PACertificate {
    [CmdletBinding()]
    [OutputType('PoshACME.PACertificate')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='Specific',ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List
    )

    Begin {
        try {
            # Make sure we have an account configured
            if (-not (Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

    }

    Process {

        # since the params in this function are a subset of the params for Get-PAOrder, we're
        # just going to pass them directly to it to get order(s) associated with the certificates
        if (-not ($orders = Get-PAOrder @PSBoundParameters)) {
            return
        }
        $orders | ForEach-Object {

            $order = $_
            $certFile = Join-Path $order.Folder 'cert.cer'

            # skip if if there's no cert file
            if (-not (Test-Path $certFile -PathType Leaf)) {
                return
            }

            $certDetails = Get-BCCertificateDetails -Pem (Get-Content $certFile -Raw)

            # convert the PfxPass to a securestring
            if ($order.PfxPass) {
                $secPfxPass = ConvertTo-SecureString $order.PfxPass -AsPlainText -Force
            } else {
                $secPfxPass = [Security.SecureString]::new()
            }

            # derive the ARI ID value
            # https://letsencrypt.org/2024/04/25/guide-to-integrating-ari-into-existing-acme-clients#step-3-constructing-the-ari-certid
            # https://www.ietf.org/archive/id/draft-ietf-acme-ari-03.html#name-the-renewalinfo-resource
            if (-not $certDetails.ARIId) {
                Write-Warning "Cert with subject $($certDetails.Subject) and serial $($certDetails.Serial) has no AKI extension. Unable to generate ARIId value."
            }

            # send the output object to the pipeline
            [pscustomobject]@{
                PSTypeName = 'PoshACME.PACertificate'

                # add the literal subject rather than just the domain name
                Subject = $certDetails.Subject

                NotBefore = $certDetails.NotBefore
                NotAfter  = $certDetails.NotAfter

                KeyLength = $order.KeyLength

                # the thumbprint is a SHA1 hash of the DER encoded cert which is not actually
                # stored in the cert itself
                Thumbprint = $certDetails.Thumbprint

                # add the ARI ID value
                ARIId = $certDetails.ARIId

                # add the serial
                Serial = $certDetails.Serial

                # add the full list of SANs
                AllSANs = [string[]]@($certDetails.AllSANs)

                # add the associated file paths whether they exist or not
                CertFile      = (Join-Path $order.Folder 'cert.cer').ToString()
                KeyFile       = (Join-Path $order.Folder 'cert.key').ToString()
                ChainFile     = (Join-Path $order.Folder 'chain.cer').ToString()
                FullChainFile = (Join-Path $order.Folder 'fullchain.cer').ToString()
                PfxFile       = (Join-Path $order.Folder 'cert.pfx').ToString()
                PfxFullChain  = (Join-Path $order.Folder 'fullchain.pfx').ToString()
                CSR           = (Join-Path $order.Folder 'request.csr').ToString()

                PfxPass = $secPfxPass
            }

        }

    }
}
