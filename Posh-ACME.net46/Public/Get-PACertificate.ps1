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

        # prep to calculate SHA1 thumbprints
        $sha1 = [Security.Cryptography.SHA1CryptoServiceProvider]::new()
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

            # import the cert
            $cert = Import-Pem -InputFile $certFile

            # build the list of SANs
            $altNames = $cert.GetSubjectAlternativeNames() | ForEach-Object {
                if ($_[0] -eq [Org.BouncyCastle.Asn1.X509.GeneralName]::DnsName) {
                    # second index is the actual DNS name
                    $_[1]
                }
                elseif ($_[0] -eq [Org.BouncyCastle.Asn1.X509.GeneralName]::IPAddress) {
                    # second index is a IP hex string like "#01010101" that we need to parse
                    ([ipaddress]([byte[]] -split ($_[1].Substring(1) -replace '..', '0x$& '))).ToString()
                }
            }

            # convert the PfxPass to a securestring
            if ($order.PfxPass) {
                $secPfxPass = ConvertTo-SecureString $order.PfxPass -AsPlainText -Force
            } else {
                $secPfxPass = [Security.SecureString]::new()
            }

            # derive the ARI ID value
            # https://letsencrypt.org/2024/04/25/guide-to-integrating-ari-into-existing-acme-clients#step-3-constructing-the-ari-certid
            # https://www.ietf.org/archive/id/draft-ietf-acme-ari-03.html#name-the-renewalinfo-resource
            $akiExt = $cert.GetExtensionValue([Org.BouncyCastle.Asn1.X509.X509Extensions]::AuthorityKeyIdentifier)
            if ($akiExt) {
                $akiBytes = [Org.BouncyCastle.Asn1.X509.AuthorityKeyIdentifier]::GetInstance($akiExt.GetOctets()).GetKeyIdentifier()
                $serialBytes = $cert.SerialNumber.ToByteArray()
                $ariID = '{0}.{1}' -f (ConvertTo-Base64Url $akiBytes),(ConvertTo-Base64Url $serialBytes)
            } else {
                Write-Warning "Cert with subject $($cert.SubjectDN) and serial $($cert.SerialNumber) has no AKI extension. Unable to generate ARIId value."
                $ariID = $null
            }

            # send the output object to the pipeline
            [pscustomobject]@{
                PSTypeName = 'PoshACME.PACertificate'

                # add the literal subject rather than just the domain name
                Subject = $cert.SubjectDN.ToString()

                # PowerShell's cert:\ provider outputs these in local time, but BouncyCastle
                # outputs in UTC. So we'll convert so they match
                NotBefore = $cert.NotBefore.ToLocalTime()
                NotAfter  = $cert.NotAfter.ToLocalTime()

                KeyLength = $order.KeyLength

                # the thumbprint is a SHA1 hash of the DER encoded cert which is not actually
                # stored in the cert itself
                Thumbprint = [BitConverter]::ToString($sha1.ComputeHash($cert.GetEncoded())).Replace('-','')

                # add the ARI ID value
                ARIId = $ariID

                # add the serial
                Serial = $cert.SerialNumber.ToString()

                # add the full list of SANs
                AllSANs = [string[]]@($altNames)

                # add the associated file paths whether they exist or not
                CertFile      = (Join-Path $order.Folder 'cert.cer').ToString()
                KeyFile       = (Join-Path $order.Folder 'cert.key').ToString()
                ChainFile     = (Join-Path $order.Folder 'chain.cer').ToString()
                FullChainFile = (Join-Path $order.Folder 'fullchain.cer').ToString()
                PfxFile       = (Join-Path $order.Folder 'cert.pfx').ToString()
                PfxFullChain  = (Join-Path $order.Folder 'fullchain.pfx').ToString()

                PfxPass = $secPfxPass
            }

        }

    }
}
