function Revoke-PACertificate {
    [CmdletBinding()]
    [OutputType('PoshACME.PACertificate')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain
    )

    Begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {

        $PACertificate = Get-PACertificate -MainDomain $MainDomain

        $certFile = $PACertificate.CertFile
        $cert = Import-Pem -InputFile $certFile
        $cert.GetEncoded()

    }

    <#
    .SYNOPSIS
        Revokes ACME certificate

    .DESCRIPTION
        Revokes a previously created ACME certificate.

    .PARAMETER MainDomain
        The primary domain associated with the certificate. This is the domain that goes in the certificate's subject.

    .EXAMPLE
        Revoke-PACertificate site.example.com

        Revokes the certificate for the specified domain.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    #>
}
