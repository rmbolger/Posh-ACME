function New-PreAuthorization {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string]$Domain
    )

    Begin {
        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # Make sure the current server actually supports pre-authorization
        if (-not $script:Dir.newAuthz) {
            try { throw "The current ACME server does not support pre-authorization." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {

        # build the protected header for the request
        $header = @{
            alg   = $acct.alg;
            kid   = $acct.location;
            nonce = $script:Dir.nonce;
            url   = $script:Dir.newAuthz;
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

        # build the payload object
        if ($Domain -match $reIPv4 -or $Domain -like '*:*') {
            Write-Debug "$Domain identified as IP address. Attempting to parse."
            $ip = [ipaddress]$Domain

            $payload = @{ identifier = @{type='ip';value=$ip.ToString()} }
        }
        else {
            $payload = @{ identifier = @{type='dns';value=$Domain} }
        }

        $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

        # send the request
        try {
            $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            $auth = $response.Content | ConvertFrom-Json
        } catch { throw }

        # inject the type name
        $auth.PSObject.TypeNames.Insert(0,'PoshACME.PAAuthorization')

        # Workaround non-compliant ACME servers such as Nexus CM that don't include
        # the status field on challenge objects. Just copy the auth's status to
        # each challenge.
        $nonCompliantServer = $false
        $auth.challenges | ForEach-Object {
            if ('status' -notin $_.PSObject.Properties.Name) {
                $nonCompliantServer = $true
                $_ | Add-Member -MemberType NoteProperty -Name 'status' -Value $auth.status
            }
        }
        if ($nonCompliantServer) {
            Write-Warning "ACME server returned non-compliant challenge objects with no status. Please report this to your ACME server vendor."
        }

        # According to RFC 8555 7.1.4 the expires property is only REQUIRED when the property status is "valid".
        # It's OPTIONAL for any other status and some CA's will not return it.
        # Only repair the timestamp if it actually exists
        if ('expires' -in $auth.PSObject.Properties.Name) {
            # fix any dates that may have been parsed by PSCore's JSON serializer
            $auth.expires = Repair-ISODate $auth.expires
        }

        # add "nice to have" members to the auth object
        # add members that expose the details of the 'dns-01' and 'http-01'
        # challenge in the root of the object
        $auth | Add-Member -NotePropertyMembers @{
            DNSId        = $auth.identifier.value
            fqdn         = "$(if ($auth.wildcard) {'*.'})$($auth.identifier.value)"
            location     = $AuthUrl
            DNS01Status  = $null
            DNS01Url     = $null
            DNS01Token   = $null
            HTTP01Status = $null
            HTTP01Url    = $null
            HTTP01Token  = $null
        }

        $dnsChallenge = $auth.challenges | Where-Object { $_.type -eq 'dns-01' }
        if ($dnsChallenge) {
            $auth.DNS01Status = $dnsChallenge.status
            $auth.DNS01Url    = $dnsChallenge.url
            $auth.DNS01Token  = $dnsChallenge.token
        }

        $httpChallenge = $auth.challenges | Where-Object { $_.type -eq 'http-01' }
        if ($httpChallenge) {
            $auth.HTTP01Status = $httpChallenge.status
            $auth.HTTP01Url    = $httpChallenge.url
            $auth.HTTP01Token  = $httpChallenge.token
        }

        Write-Output $auth

    }
}
