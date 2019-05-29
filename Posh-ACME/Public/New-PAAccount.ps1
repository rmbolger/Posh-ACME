function New-PAAccount {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('PoshACME.PAAccount')]
    param(
        [Parameter(Position=0)]
        [string[]]$Contact,
        [Parameter(Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [Alias('AccountKeyLength')]
        [string]$KeyLength='ec-256',
        [switch]$AcceptTOS,
        [switch]$Force,
        [Parameter(ValueFromRemainingArguments=$true)]
        $ExtraParams
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # make sure the Contact emails have a "mailto:" prefix
    # this may get more complex later if ACME servers support more than email based contacts
    if ($Contact.Count -gt 0) {
        0..($Contact.Count-1) | ForEach-Object {
            if ($Contact[$_] -notlike 'mailto:*') {
                $Contact[$_] = "mailto:$($Contact[$_])"
            }
        }
    } else {
        Write-Warning "No email contacts specified for this account. Certificate expiration warnings will not be sent unless you add at least one with Set-PAAccount."
    }

    # There's a chance we may be creating effectively a duplicate account. So check
    # for confirmation if there's already one with the same contacts and keylength.
    if (!$Force) {
        $accts = @(Get-PAAccount -List -Refresh -Contact $Contact -KeyLength $KeyLength -Status 'valid')
        if ($accts.Count -gt 0) {
            if (!$PSCmdlet.ShouldContinue("Do you wish to duplicate?",
                "Existing account with matching contacts and key length.")) { return }
        }
    }

    Write-Debug "Creating new $KeyLength account with contact: $($Contact -join ', ')"

    # create the account key
    $acctKey = New-PAKey $KeyLength

    # create the algorithm identifier as described by
    # https://tools.ietf.org/html/rfc7518#section-3.1
    # and what we know LetsEncrypt supports today which includes
    # RS256 for all RSA keys
    # ES256 for P-256 keys, ES384 for P-384 keys, ES512 for P-521 keys
    $alg = 'RS256'
    if     ($KeyLength -eq 'ec-256') { $alg = 'ES256' }
    elseif ($KeyLength -eq 'ec-384') { $alg = 'ES384' }
    elseif ($KeyLength -eq 'ec-521') { $alg = 'ES512' }

    # build the protected header for the request
    $header = @{
        alg   = $alg;
        jwk   = ($acctKey | ConvertTo-Jwk -PublicOnly);
        nonce = $script:Dir.nonce;
        url   = $script:Dir.newAccount;
    }

    # init the payload
    $payload = @{}
    if ($Contact.Count -gt 0) {
        $payload.contact = $Contact
    }
    if ($AcceptTOS) {
        $payload.termsOfServiceAgreed = $true
    }

    # convert it to json
    $payloadJson = $payload | ConvertTo-Json -Compress

    # send the request
    try {
        $response = Invoke-ACME $header $payloadJson -Key $acctKey -EA Stop
    } catch { throw }
    Write-Debug "Response: $($response.Content)"

    # grab the Location header
    if ($response.Headers.ContainsKey('Location')) {
        $location = $response.Headers['Location'] | Select-Object -First 1
    } else {
        throw 'No Location header found in newAccount output'
    }

    $respObj = $response.Content | ConvertFrom-Json

    # So historically, LE/Boulder returns the raw account ID value as a property in the JSON
    # output for new account requests. But the finalized RFC 8555 does not require this
    # and Boulder will be removing it. But it's still a useful value to have for referencing
    # accounts. So if it's not returned, we're going to try and parse it from the location
    # header. This may come back to haunt us if other ACME providers use different location
    # schemes in the future.
    if (-not $respObj.ID) {
        # https://acme-staging-v02.api.letsencrypt.org/acme/acct/xxxxxxxx
        # https://acme-v02.api.letsencrypt.org/acme/acct/xxxxxxxx
        $acctID = $location.Substring($location.LastIndexOf('/')+1)
    } else {
        $acctID = $respObj.ID.ToString()
    }

    # build the return value
    $acct = [pscustomobject]@{
        PSTypeName = 'PoshACME.PAAccount'
        id = $acctID
        status = $respObj.status
        contact = $respObj.contact
        location = $location
        key = ($acctKey | ConvertTo-Jwk)
        alg = $alg
        KeyLength = $KeyLength
        # The orders field is supposed to exist according to
        # https://tools.ietf.org/html/rfc8555#section-7.1.2
        # But it's not currently implemented in Boulder. Tracking issue is here:
        # https://github.com/letsencrypt/boulder/issues/3335
        orders = $respObj.orders
    }

    # save it to memory and disk
    $acct.id | Out-File (Join-Path $script:DirFolder 'current-account.txt') -Force -EA Stop
    $script:Acct = $acct
    $script:AcctFolder = Join-Path $script:DirFolder $acct.id
    if (!(Test-Path $script:AcctFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $script:AcctFolder -Force -EA Stop | Out-Null
    }
    $acct | ConvertTo-Json | Out-File (Join-Path $script:AcctFolder 'acct.json') -Force -EA Stop

    return $acct




    <#
    .SYNOPSIS
        Create a new account on the current ACME server.

    .DESCRIPTION
        All certificate requests require a valid account on an ACME server. Adding an email contact is not required. But without one, certificate expiration notices will not be sent. The account KeyLength is personal preference and doesn't correspond to the KeyLength of the generated certificates.

    .PARAMETER Contact
        One or more email addresses to associate with this account. These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

    .PARAMETER KeyLength
        The type and size of private key to use. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to 'ec-256'.

    .PARAMETER AcceptTOS
        If not specified, the ACME server will throw an error with a link to the current Terms of Service. Using this switch indicates acceptance of those Terms of Service and is required for successful account creation.

    .PARAMETER Force
        If specified, confirmation prompts that may have been generated will be skipped.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        New-PAAccount -AcceptTOS

        Create a new account with no contact email and the default key length.

    .EXAMPLE
        New-PAAccount -Contact user1@example.com -AcceptTOS

        Create a new account with the specified email and the default key length.

    .EXAMPLE
        New-PAAccount -Contact user1@example.com -KeyLength 4096 -AcceptTOS

        Create a new account with the specified email and an RSA 4096 bit key.

    .EXAMPLE
        New-PAAccount -KeyLength 'ec-384' -AcceptTOS -Force

        Create a new account with no contact email and an ECC key using P-384 curve that ignores any confirmations.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAccount

    .LINK
        Set-PAAccount

    #>
}
