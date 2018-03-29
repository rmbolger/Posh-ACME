function Set-PAAccount {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$id,
        [string[]]$Contact,
        [switch]$Deactivate
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # check if we're switching accounts
    if ($id) {

        # check for the account folder
        $acctFolder = Join-Path $script:DirUrlFolder $id
        if (!(Test-Path $acctFolder -PathType Container)) {
            throw "No account folder found with id $id."
        }

        # try to load the acct.json file
        $acct = Get-Content (Join-Path $acctFolder 'acct.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

        # save it to memory
        $script:Acct = $acct

    } else {

        # just use the current account
        $acct = $script:Acct
        $id = $acct.id
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

        # save it to and disk
        $acctFolder = Join-Path $script:DirUrlFolder $acct.id
        $acct | ConvertTo-Json | Out-File (Join-Path $acctFolder 'acct.json') -Force

    }

    return $acct
}
