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
            throw "No ACME account configured. Run New-PAAccount or specify an account ID."
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

        } elseif (!$script:Acct -or ($ID -and ($ID -ne $script:Acct.id))) {
            # This is a definite account switch

            # refresh the cached copy
            Update-PAAccount $ID

            Write-Verbose "Switching to account $ID"

            # save it as current
            $ID | Out-File (Join-Path $script:DirFolder 'current-account.txt') -Force

            # reset child object references
            $script:Order = $null
            $script:OrderFolder = $null

            # reload the cache from disk
            Import-PAConfig 'Account'

            # grab a local reference to the newly current account
            $acct = $script:Acct

        } else {
            # This is effectively a non-switching modification because they didn't
            # specify an ID. So just use the current account.
            $acct = $script:Acct
        }

        # check if there's anything to change
        if ('Contact' -in $PSBoundParameters.Keys -or $Deactivate) {

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
            if ('Contact' -in $PSBoundParameters.Keys) {
                # We want to allow people to clear their contact field either by specifying $null or an empty array @()
                # But currently, Boulder only works by sending the empty array. So use that if they sent $null.
                if (!$Contact) {
                    $payload.contact = @()
                } else {
                    $payload.contact = $Contact
                }
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





    <#
    .SYNOPSIS
        Set the current ACME account and/or update account details.

    .DESCRIPTION
        This function allows you to switch between ACME accounts for a particular server. It also allows you to update the contact information associated with an account or deactivate the account.

    .PARAMETER ID
        The account id value as returned by the ACME server. If not specified, the function will attempt to use the currently active account.

    .PARAMETER Contact
        One or more email addresses to associate with this account. These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

    .PARAMETER Deactivate
        If specified, a request will be sent to the associated ACME server to deactivate the account. Clients may wish to do this if the account key is compromised or decommissioned.

    .PARAMETER NoSwitch
        If specified, the currently active account will not change. Useful primarily for bulk updating contact information across accounts. This switch is ignored if no ID is specified.

    .EXAMPLE
        Set-PAAccount -ID 1234567

        Switch to the specified account.

    .EXAMPLE
        Set-PAAccount -Contact 'user1@example.com','user2@example.com'

        Set new contacts for the current account.

    .EXAMPLE
        Set-PAAccount -ID 1234567 -Contact 'user1@example.com','user2@example.com'

        Set new contacts for the specified account.

    .EXAMPLE
        Get-PAAccount -List | Set-PAAccount -Contact user1@example.com -NoSwitch

        Set a new contact for all known accounts without switching from the current.

    .EXAMPLE
        Set-PAAccount -Deactivate

        Deactivate the current account.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAccount

    .LINK
        New-PAAccount

    #>
}
