function Invoke-ChallengeValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=1)]
        [string[]]$AuthUrls,
        [Parameter(Mandatory,Position=2)]
        [string[]]$ChallengeUrls,
        [int]$SecondsToWait=60
    )

    # The purpose of this function is to notify the ACME server that we're ready for it to
    # validate the challenges that we've responded to and then wait for it to finish
    # those validations by checking the status of the associated authorizations.

    # We'll basically poll the authorizations until they are all valid or any one is
    # not valid (invalid, revoked, deactivated, expired) or our timeout elapses.

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # hydrate the key
    $key = $Account.key | ConvertFrom-Jwk

    # build the protected header template for the request
    $header = @{
        alg   = $Account.alg;
        kid   = $Account.location;
        nonce = '';
        url   = '';
    }

    # the payload is an empty object
    $payloadJson = '{}'

    foreach ($chalUrl in $ChallengeUrls) {
        # update the header for this challenge
        $header.nonce = $script:Dir.nonce
        $header.url   = $chalUrl

        # send the request
        $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop
        Write-Verbose "$($response.Content)"
    }

    # now we poll
    $allValid = $false
    $skips = @()
    for ($tries=1; $tries -le ($SecondsToWait/2); $tries++) {

        for ($i=0; $i -lt $AuthUrls.Count; $i++) {

            # don't re-query things we know are already valid
            if ($i -in $skips) { continue; }

            $auth = Get-PAAuthorizations $AuthUrls[$i] -Verbose:$false
            Write-Verbose "T$tries Authorization for $($auth.fqdn) status '$($auth.status)'."

            if ($auth.status -eq 'valid') {
                # add this to the skip list
                $skips += $i

            } elseif ($auth.status -eq 'pending') {
                # do nothing so we just try again during the next poll
                continue

            } else {
                # got one of the bad statuses, so error out
                throw "Authorization for $($auth.fqdn) returned status '$($auth.status)'."
            }
        }

        # If we have any remaining, sleep. Otherwise, break/return
        if ($skips.Count -lt $AuthUrls.Count) {
            Start-Sleep 2
        } else {
            $allValid = $true
            break
        }
    }

    if (!$allValid) {
        throw "Timed out waiting $SecondsToWait seconds for authorizations to become valid."
    }

}
