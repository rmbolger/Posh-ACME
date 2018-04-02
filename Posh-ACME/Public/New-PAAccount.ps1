function New-PAAccount {
    [CmdletBinding()]
    param(
        [string[]]$Contact,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048',
        [switch]$AcceptTOS
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # create the account key
    $key = New-PAKey $KeyLength

    # build the protected header for the request
    $header = @{
        alg   = (Get-JwsAlg $key);
        jwk   = ($key | ConvertTo-Jwk -PublicOnly);
        nonce = $script:NextNonce;
        url   = $script:Dir.newAccount;
    }

    # init the payload
    $payload = @{}

    # make sure the Contact emails have a "mailto:" prefix
    # this may get more complex later if ACME servers support more than email based contacts
    if ($Contact.Count -gt 0) {
        0..($Contact.Count-1) | ForEach-Object {
            if ($Contact[$_] -notlike 'mailto:*') {
                $Contact[$_] = "mailto:$($Contact[$_])"
            }
        }
        $payload.contact = $Contact
    }

    # accept the Terms of Service
    if ($AcceptTOS) {
        $payload.termsOfServiceAgreed = $true
    }

    # convert it to json
    $payloadJson = $payload | ConvertTo-Json -Compress

    # send the request
    $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop

    # grab the Location header
    if ($response.Headers.ContainsKey('Location')) {
        $location = $response.Headers['Location']
    } else {
        throw 'No Location header found in newAccount output'
    }

    # build the return value
    $respObj = $response.Content | ConvertFrom-Json
    $acct = [pscustomobject]@{
        PSTypeName = 'PoshACME.PAAccount';
        id = $respObj.ID.ToString();    # Boulder currently returns ID as an integer
        status = $respObj.status;
        contact = $respObj.contact;
        location = $location;
        key = ($key | ConvertTo-Jwk);
        alg = (Get-JwsAlg $key);
        KeyLength = $KeyLength;
        # This is supposed to exist according to https://tools.ietf.org/html/draft-ietf-acme-acme-10#section-7.1.2
        # But it's not currently showing up via Pebble or the LE v2 Staging server
        orderlocation = $respObj.orders;
    }

    # save it to memory and disk
    $acct.id | Out-File (Join-Path $script:DirFolder 'current-account.txt') -Force
    $script:Acct = $acct
    $script:AcctFolder = Join-Path $script:DirFolder $acct.id
    if (!(Test-Path $script:AcctFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $script:AcctFolder -Force | Out-Null
    }
    $acct | ConvertTo-Json | Out-File (Join-Path $script:AcctFolder 'acct.json') -Force

    return $acct
}