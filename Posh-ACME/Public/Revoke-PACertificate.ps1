function Revoke-PACertificate {
    [CmdletBinding(
        DefaultParameterSetName='MainDomain',
        SupportsShouldProcess,
        ConfirmImpact='High'
    )]
    param(
        [Parameter(ParameterSetName='MainDomain',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ParameterSetName='MainDomain',ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name,
        [Parameter(ParameterSetName='CertFile',Mandatory,ValueFromPipelineByPropertyName)]
        [string]$CertFile,
        [Parameter(ParameterSetName='CertFile',ValueFromPipelineByPropertyName)]
        [string]$KeyFile,
        [PoshACME.RevocationReasons]$Reason,
        [switch]$Force
    )

    Begin {
        # grab a reference to the current account if it exists
        $acct = Get-PAAccount

        if ($Force){
            $ConfirmPreference = 'None'
        }

        $pemHeader = '-----BEGIN CERTIFICATE-----'
        $pemFooter = '-----END CERTIFICATE-----'
    }

    Process {

        if ('MainDomain' -eq $PSCmdlet.ParameterSetName) {

            # check for a unique matching order
            if ($Name) {
                $order = Get-PAOrder -Name $Name
                if (-not $order) {
                    Write-Error "No order found matching Name '$Name'."
                    return
                }
            } else {
                $matchingOrders = Get-PAOrder -List | Where-Object { $_.MainDomain -eq $MainDomain }
                if ($matchingOrders.Count -eq 1) {
                    $order = $matchingOrders
                } elseif ($matchingOrders.Count -ge 2) {
                    # error because we can't be sure which object to affect
                    Write-Error "Multiple orders found for MainDomain '$MainDomain'. Please specify Name as well."
                    return
                } else {
                    Write-Error "No order found matching MainDomain '$MainDomain'."
                    return
                }
            }

            # check for an existing certificate
            if (-not ($paCert = $order | Get-PACertificate)) {
                try { throw "No existing certificate found for $MainDomain." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }

            # set the cert/key file paths
            $CertFile = $paCert.CertFile
            $KeyFile = $paCert.KeyFile
        }

        # do some minimal sanity checking on the cert file contents
        try {
            $certStr = (Get-Content $CertFile -EA Stop) -join ''
            if (-not ($certStr.StartsWith($pemHeader) -and $certStr.EndsWith($pemFooter))) {
                throw "Malformed certificate file: $CertFile"
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

        # remove the header/footer and convert to Base64Url as ACME expects
        $certStr = $certStr.Replace($pemHeader,'').Replace($pemFooter,'') |
            ConvertTo-Base64Url -FromBase64

        # Now we need to decide how we're going to sign to request. It can either
        # be signed with the private key that matches the cert or an ACME account
        # key. The ACME account must either be the one that orderd the cert
        # or one that has currently valid authorizations for all identifiers in
        # the cert.
        #     https://datatracker.ietf.org/doc/html/rfc5280#section-5.3.1
        #
        # We're always going to try and use the cert's private key if
        # it is specified even if we could also use the current account's key.

        # check the private key
        if ($KeyFile) {
            if (Test-Path $KeyFile -PathType Leaf) {
                try {
                    $certKey = Import-Pem -InputFile $KeyFile | ConvertFrom-BCKey
                }
                catch {
                    Write-Warning "Unable to import private key file $($KeyFile): $($_.Exception.Message). Will attempt revocation with account key."
                }
            }
            else {
                Write-Warning "Private key $KeyFile was not found. Will attempt revocation with account key."
            }
        }
        else { Write-Debug "No KeyFile passed. Will attempt revocation with account key." }

        # start building the splat for Invoke-ACME
        $acmeParams = @{
            ErrorAction = 'Stop'
        }

        if ($certKey) {
            Write-Debug "Attempting to use cert key"

            # determine the alg from the key
            $alg = 'RS256'
            if ($certKey -is [Security.Cryptography.ECDsa]) {
                if     ($certKey.KeySize -eq 256) { $alg = 'ES256' }
                elseif ($certKey.KeySize -eq 384) { $alg = 'ES384' }
                elseif ($certKey.KeySize -eq 521) { $alg = 'ES512' }
            }

            # build the protected header
            $acmeParams.Header = @{
                alg   = $alg
                jwk   = ($certKey | ConvertTo-Jwk -PublicOnly)
                nonce = $script:Dir.nonce
                url   = $script:Dir.revokeCert
            }

            # set the key
            $acmeParams.Key = $certKey

        } elseif (-not $acct) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }

        } else {
            Write-Debug "Attempting to use account key"

            # build the protected header
            $acmeParams.Header = @{
                alg   = $acct.alg
                kid   = $acct.location
                nonce = $script:Dir.nonce
                url   = $script:Dir.revokeCert
            }

            # set the account
            $acmeParams.Account = $acct
        }

        # build the payload
        $payload = @{ certificate = $certStr }
        if ($Reason) {
            $payload.reason = $Reason
        }
        $acmeParams.PayloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

        # send the request
        if ($PSCmdlet.ShouldProcess($CertFile)){
            try {
                Invoke-ACME @acmeParams | Out-Null
            } catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

    }

    <#
    .SYNOPSIS
        Revoke an ACME certificate

    .DESCRIPTION
        Revokes a previously created ACME certificate.

    .PARAMETER MainDomain
        The primary domain associated with the certificate to be revoked.

    .PARAMETER Name
        The name of the ACME order. This can be useful to distinguish between two orders that have the same MainDomain.

    .PARAMETER CertFile
        A PEM-encoded certificate file to be revoked.

    .PARAMETER KeyFile
        The PEM-encoded private key associated with CertFile. If not specified, the current ACME account will be used to sign the request.

    .PARAMETER Reason
        The reason for cert revocation. This must be one of the reasons defined in RFC 5280 including keyCompromise, cACompromise, affiliationChanged, superseded, cessationOfOperation, certificateHold, removeFromCRL, privilegeWithdrawn, and aACompromise. NOTE: Not all reason codes are supported by all ACME certificate authorities.

    .PARAMETER Force
        If specified, the revocation confirmation prompt will be skipped.

    .EXAMPLE
        Revoke-PACertificate example.com

        Revokes the certificate for the specified domain.

    .EXAMPLE
        Get-PAOrder | Revoke-PACertificate -Force

        Revokes the certificate associated with the current order and skips the confirmation prompt.

    .EXAMPLE
        Get-PACertificate | Revoke-PACertificate -Reason keyCompromise

        Revokes the current certificate with the specified reason.

    .EXAMPLE
       Revoke-PACertificate -CertFile mycert.crt -KeyFile mycert.key

       Revokes the specified cert using the specified private key.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    #>
}

# Define an enum to represent the revocations reasons defined in RFC 5280
# that ACME supports.
# https://datatracker.ietf.org/doc/html/rfc8555#section-7.6
# https://datatracker.ietf.org/doc/html/rfc5280#section-5.3.1
if (-not ([System.Management.Automation.PSTypeName]'PoshACME.RevocationReasons').Type)
{
    Add-Type @"
        namespace PoshACME {
            public enum RevocationReasons {
                keyCompromise        = 1,
                cACompromise         = 2,
                affiliationChanged   = 3,
                superseded           = 4,
                cessationOfOperation = 5,
                certificateHold      = 6,
                removeFromCRL        = 8,
                privilegeWithdrawn   = 9,
                aACompromise         = 10
            }
        }
"@
}
