function Set-PAAccount {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='ID',Position=0,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$ID,
        [Parameter(ParameterSetName='Search',Position=0,Mandatory)]
        [switch]$Search,
        [Parameter(ParameterSetName='ID')]
        [Parameter(ParameterSetName='Search',Position=1)]
        [string[]]$Contact,
        [Parameter(ParameterSetName='Search',Position=2)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='2048',
        [Parameter(ParameterSetName='ID')]
        [switch]$Deactivate,
        [Parameter(ParameterSetName='Search')]
        [switch]$CreateIfNecessary,
        [Parameter(ParameterSetName='Search')]
        [switch]$AcceptTOS,
        [Parameter(ValueFromRemainingArguments=$true)]
        $ExtraParams
    )

    # There are two distinct modes in this function, ID and Search mode.
    #
    # ID mode means we're explicitly switching to an existing Account by its ID
    # and optionally updating its properties on the server. If no ID is specified,
    # we're just updating the current account's properties.
    #
    # Search mode means we're trying to find an existing account that matches
    # either or both of the Contact/KeyLength field. If -CreateIfNecessary is specified,
    # we'll attempt to create a new account if the search didn't find any matches.
    # If multiple matches are found, the first one is used.

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # Regardless of mode, make sure all Contacts have a mailto: prefix which is the only
    # type of contact currently supported.
    if ($Contact.Count -gt 0) {
        0..($Contact.Count-1) | ForEach-Object {
            if ($Contact[$_] -notlike 'mailto:*') {
                $Contact[$_] = "mailto:$($Contact[$_])"
            }
        }
    }

    if ('ID' -eq $PSCmdlet.ParameterSetName) {
        # ID Mode

        # check if we're switching accounts
        if ($ID -and $ID -ne $script:Acct.id) {

            # check for the account folder
            $acctFolder = Join-Path $script:DirFolder $ID
            if (!(Test-Path $acctFolder -PathType Container)) {
                throw "No account folder found with id '$ID'."
            }

            # try to load the acct.json file
            $acct = Get-Content (Join-Path $acctFolder 'acct.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

            # save it
            $acct.id | Out-File (Join-Path $script:DirFolder 'current-account.txt') -Force

            # reset child object references
            $script:Order = $null
            $script:OrderFolder = $null

            Import-PAConfig

        } else {

            # just use the current account
            $acct = $script:Acct
            $ID = $acct.id
        }

        # check if there's anything to change
        if ($Contact -or $Deactivate) {

            # hydrate the key
            $key = $acct.key | ConvertFrom-Jwk

            # build the header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:NextNonce;
                url   = $acct.location;
            }

            # build the payload
            $payload = @{}

            if ($Contact) {
                # make sure the Contact emails have a "mailto:" prefix
                # this may get more complex later if ACME servers support more than email based contacts
                if ($Contact.Count -gt 0) {
                    0..($Contact.Count-1) | ForEach-Object {
                        if ($Contact[$_] -notlike 'mailto:*') {
                            $Contact[$_] = "mailto:$($Contact[$_])"
                        }
                    }
                }
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

            $respObj = ($response.Content | ConvertFrom-Json);

            # update the things that could have changed
            $acct.status = $respObj.status
            $acct.contact = $respObj.contact
            $acct.orderlocation = $respObj.orders

            # save it to disk
            $acctFolder = Join-Path $script:DirFolder $acct.id
            $acct | ConvertTo-Json | Out-File (Join-Path $acctFolder 'acct.json') -Force

        }

        return $acct

    } else {
        # Search Mode

        # The one special case in this mode is if the caller doesn't specify any
        # search conditions and there's already an account set. We just want to leave
        # the current account selected rather than switch to whatever random account
        # shows up first in the list.
        $psbKeys = $PSBoundParameters.Keys
        if ((Get-PAAccount) -and ('Contact' -notin $psbKeys) -and ('AccountKeyLength' -notin $psbKeys)) {
            # do nothing other than return the already selected account
            return (Get-PAAccount)
        }

        # get the current list of accounts to search within
        $accounts = @(Get-PAAccount -List)
        Write-Verbose "Searching $($accounts.Count) account(s)"

        # narrow it down by key length if specified
        if ($accounts.Count -gt 0 -and 'AccountKeyLength' -in $PSBoundParameters.Keys) {

            $accounts = @($accounts | Where-Object {
                $_.KeyLength -eq $AccountKeyLength
            })
            Write-Verbose "$($accounts.Count) remaining after checking KeyLength"
        }

        # narrow it down by contacts if specified
        if ($accounts.Count -gt 0 -and 'Contact' -in $PSBoundParameters.Keys) {

            # sort and join the array to make it easier to compare
            $searchContacts = ($Contact | Sort-Object) -join ','

            $accounts = @($accounts | Where-Object {
                $searchContacts -eq (($_.contact | Sort-Object) -join ',')
            })
            Write-Verbose "$($accounts.Count) remaining after checking Contact"
        }

        # check if we have any left
        if ($accounts.Count -gt 0) {

            # at least one left, so set the first one via a recursive call
            # based on the ID
            Write-Verbose "Setting first match"
            return ($accounts[0] | Set-PAAccount)

        } elseif ($CreateIfNecessary -and $AcceptTOS) {

            # create and return the new account
            return (New-PAAccount -Contact $Contact -KeyLength $AccountKeyLength -AcceptTOS)

        } elseif ($CreateIfNecessary) {

            # they forgot to accept the TOS
            throw "The -AcceptTOS parameter is required when creating a new account. Please review the Terms of Service here: $($script:Dir.meta.termsOfService)"

        } else {
            # just throw an error because we didn't find any matches
            throw "No accounts found matching the specified parameters."
        }

    }

}
