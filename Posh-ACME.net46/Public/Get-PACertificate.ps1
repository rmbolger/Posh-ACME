function Get-PACertificate {
    [CmdletBinding()]
    [OutputType('PoshACME.PACertificate')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {

        # List mode
        if ('List' -eq $PSCmdlet.ParameterSetName) {

            # get the list of orders
            $orders = Get-PAOrder -List | Where-Object { $_.CertExpires }

            # recurse for each complete order
            $orders | Get-PACertificate

        # Specific mode
        } else {

            if ($MainDomain) {
                # query the specified order
                $order = Get-PAOrder $MainDomain
            } else {
                # just use the current one
                $order = $script:Order
            }

            # return early if there's no order
            if ($null -eq $order) { return $null }

            # build the path to cert.cer
            $domainFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
            $certFile = Join-Path $domainFolder 'cert.cer'

            # double check the cert exists
            if (!(Test-Path $certFile -PathType Leaf)) {
                return $null
            }

            # import the cert
            $cert = Import-Pem -InputFile $certFile

            $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
            $allSANs = @($order.MainDomain); if ($order.SANs.Count -gt 0) { $allSANs += @($order.SANs) }

            # create the output object
            $pacert = [pscustomobject]@{
                PSTypeName = 'PoshACME.PACertificate';

                # add the literal subject rather than just the domain name
                Subject = $cert.SubjectDN.ToString();

                # PowerShell's cert:\ provider outputs these in local time, but BouncyCastle outputs in
                # UTC, so we'll convert so they match
                NotBefore = $cert.NotBefore.ToLocalTime();
                NotAfter  = $cert.NotAfter.ToLocalTime();

                KeyLength = $order.KeyLength;

                # the thumbprint is a SHA1 hash of the DER encoded cert which is not actually
                # stored in the cert itself
                Thumbprint = [BitConverter]::ToString($sha1.ComputeHash($cert.GetEncoded())).Replace('-','')

                # add the full list of SANs
                AllSANs = $allSANs

                # add the associated files
                CertFile      = Join-Path $domainFolder 'cert.cer'
                KeyFile       = Join-Path $domainFolder 'cert.key'
                ChainFile     = Join-Path $domainFolder 'chain.cer'
                FullChainFile = Join-Path $domainFolder 'fullchain.cer'
                PfxFile       = Join-Path $domainFolder 'cert.pfx'
                PfxFullChain  = Join-Path $domainFolder 'fullchain.pfx'

                PfxPass = $( if ($order.PfxPass) {
                                ConvertTo-SecureString $order.PfxPass -AsPlainText -Force
                            } else { New-Object Security.SecureString } )

            }

            return $pacert
        }
    }





    <#
    .SYNOPSIS
        Get ACME certificate details.

    .DESCRIPTION
        Returns details such as Thumbprint, Subject, Validity, SANs, and file locations for one or more ACME certificates previously created.

    .PARAMETER MainDomain
        The primary domain associated with the certificate. This is the domain that goes in the certificate's subject.

    .PARAMETER List
        If specified, the details for all completed certificates will be returned for the current account.

    .EXAMPLE
        Get-PACertificate

        Get cached ACME order details for the currently selected order.

    .EXAMPLE
        Get-PACertificate site.example.com

        Get cached ACME order details for the specified domain.

    .EXAMPLE
        Get-PACertificate -List

        Get all cached ACME order details.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    #>
}
