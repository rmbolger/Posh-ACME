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
        try {
            # Make sure the current server actually supports pre-authorization
            if (-not $script:Dir.newAuthz) {
                throw "The current ACME server does not support pre-authorization. Use New-PAOrder or New-PACertificate instead."
            }

            # Make sure there's a valid account
            if (-not $Account) {
                if (-not ($Account = Get-PAAccount)) {
                    throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
                }
            }
            if ($Account.status -ne 'valid') {
                throw "Account status is $($Account.status)."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
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
            if (Test-IPShaped $name) {
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
