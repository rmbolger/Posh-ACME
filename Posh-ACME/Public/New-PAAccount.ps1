function New-PAAccount {
    [OutputType('PoshACME.PAAccount')]
    [CmdletBinding(SupportsShouldProcess)]
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

    Write-Verbose "Creating new $KeyLength account with contact: $($Contact -join ', ')"

    # create the account key
    $key = New-PAKey $KeyLength

    # build the protected header for the request
    $header = @{
        alg   = (Get-JwsAlg $key);
        jwk   = ($key | ConvertTo-Jwk -PublicOnly);
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
        $response = Invoke-ACME $header.url $key $header $payloadJson -EA Stop
    } catch { throw }

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
        # This is supposed to exist according to https://tools.ietf.org/html/draft-ietf-acme-acme-11#section-7.1.2
        # But it's not currently showing up via Pebble or Boulder
        orders = $respObj.orders;
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
