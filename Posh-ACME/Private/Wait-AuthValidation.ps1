function Wait-AuthValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$AuthUrls,
        [Parameter(Mandatory,Position=1)]
        [int]$ValidationTimeout
    )

    # now we poll
    $allValid = $false
    $skips = @()
    for ($tries=1; $tries -le ($ValidationTimeout/2); $tries++) {

        for ($i=0; $i -lt $AuthUrls.Count; $i++) {

            # don't re-query things we know are already valid
            if ($i -in $skips) { continue; }

            $auth = Get-PAAuthorizations $AuthUrls[$i] -Verbose:$false
            Write-Debug "T$tries Authorization for $($auth.fqdn) status '$($auth.status)'."

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
        throw "Timed out waiting $ValidationTimeout seconds for authorizations to become valid."
    }

}
