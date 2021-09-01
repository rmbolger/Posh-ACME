function New-PAAuthorization {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string[]]$Domain,
        [Parameter(Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account
    )

    Begin {
        # Make sure the current server actually supports pre-authorization
        if (-not $script:Dir.newAuthz) {
            try { throw "The current ACME server does not support pre-authorization. Use New-PAOrder or New-PACertificate instead." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # Make sure there's a valid account
        if (-not $Account) {
            if (-not ($Account = Get-PAAccount)) {
                try { throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }
        if ($Account.status -ne 'valid') {
            try { throw "Account status is $($Account.status)." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # super lazy IPv4 address regex, but we just need to be able to
        # distinguish from an FQDN
        $reIPv4 = [regex]'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'

        # IP identifiers (RFC8738) are an extension to the original ACME protocol
        # https://tools.ietf.org/html/rfc8738
        #
        # So we have to distinguish between domain FQDNs and IPv4/v6 addresses
        # and send the appropriate identifier type for each one. We don't care
        # if the IP address entered is actually valid or not, only that it is
        # parsable as an IP address and should be sent as one rather than a
        # DNS name.
    }

    Process {

        foreach ($name in $Domain) {

            # build the protected header for the request
            $header = @{
                alg   = $Account.alg;
                kid   = $Account.location;
                nonce = $script:Dir.nonce;
                url   = $script:Dir.newAuthz;
            }

            # build the payload object
            if ($name -match $reIPv4 -or $name -like '*:*') {
                Write-Debug "$name identified as IP address. Attempting to parse."
                $ip = [ipaddress]$name

                $payload = @{ identifier = @{type='ip';value=$ip.ToString()} }
            }
            else {
                $payload = @{ identifier = @{type='dns';value=$name} }
            }

            $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

            # send the request
            try {
                $response = Invoke-ACME $header $payloadJson $Account -EA Stop

                # grab the location from the header
                if ($response.Headers.ContainsKey('Location')) {
                    $location = $response.Headers['Location'] | Select-Object -First 1
                } else {
                    throw 'No Location header found in response output'
                }
            } catch {
                Write-Error $_
                continue
            }

            ConvertTo-PAAuthorization $response.Content $location

        }
    }
}
