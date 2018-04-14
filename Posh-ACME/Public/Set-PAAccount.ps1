function Set-PAAccount {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ID,
        [Parameter(Position=1)]
        [string[]]$Contact,
        [switch]$Deactivate,
        [switch]$NoSwitch
    )

    Begin {
        # make sure we have a server configured
        if (!(Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }

        # make sure all Contacts have a mailto: prefix which is the only
        # type of contact currently supported.
        if ($Contact.Count -gt 0) {
            0..($Contact.Count-1) | ForEach-Object {
                if ($Contact[$_] -notlike 'mailto:*') {
                    $Contact[$_] = "mailto:$($Contact[$_])"
                }
            }
        }
    }

    Process {

        # throw an error if there's no current account and no ID
        # passed in
        if (!$script:Acct -and !$ID) {
            throw "No ACME account configured. Run Set-PAAccount or specify an account ID."
        }

        # There are 3 types of calls the user might be making here.
        # - account switch
        # - account switch and modification
        # - modification only (possibly bulk via pipeline)
        # The default is to switch accounts. So we have a -NoSwitch parameter to
        # indicate a non-switching modification. But there's a chance they could forget
        # to use it for a bulk update. For now, we'll just let it happen and switch
        # to whatever account came through the pipeline last.

        if ($NoSwitch -and $ID) {
            # This is a non-switching modification, so grab a cached reference to the
            # account specified
            $acct = Get-PAAccount $ID

        } elseif (!$script:Acct -or ($script:Acct.id -ne $ID)) {
            # This is a definite account switch

            # Check for the associated account folder. Even if this account
            # ID exists on the server, we can't do anything with it unless we
            # have the associated private key.
            $acctFolder = Join-Path $script:DirFolder $ID
            if (!(Test-Path $acctFolder -PathType Container)) {
                throw "No account found with id '$ID'."
            }

            # save it as current
            $acct.id | Out-File (Join-Path $script:DirFolder 'current-account.txt') -Force

            # reset child object references
            $script:Order = $null
            $script:OrderFolder = $null

            # refresh the cached copy
            Update-PAAccount $acct.id

            # reload the cache from disk
            Import-PAConfig

            # grab a local reference to the newly current account
            $acct = $script:Acct

        } else {
            # This is effectively a non-switching modification because they didn't
            # specify an ID. So just use the current account.
            $acct = $script:Acct
        }

        # check if there's anything to change
        if ($Contact -or $Deactivate) {

            # hydrate the key
            $key = $acct.key | ConvertFrom-Jwk

            # build the header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:Dir.nonce;
                url   = $acct.location;
            }

            # build the payload
            $payload = @{}
            if ($Contact) {
                $payload.contact = $Contact
            }
            if ($Deactivate) {
                $payload.status = 'deactivated'
            }

            # convert it to json
            $payloadJson = $payload | ConvertTo-Json -Compress

            # send the request
            $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop
            Write-Verbose $response.Content

            $respObj = ($response.Content | ConvertFrom-Json)

            # update the things that could have changed
            $acct.status = $respObj.status
            $acct.contact = $respObj.contact

            # save it to disk
            $acctFolder = Join-Path $script:DirFolder $acct.id
            $acct | ConvertTo-Json | Out-File (Join-Path $acctFolder 'acct.json') -Force
        }

    }

}
