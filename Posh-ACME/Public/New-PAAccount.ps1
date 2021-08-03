function New-PAAccount {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='Generate')]
    [OutputType('PoshACME.PAAccount')]
    param(
        [Parameter(Position=0)]
        [string[]]$Contact,
        [Parameter(ParameterSetName='Generate',Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [Alias('AccountKeyLength')]
        [string]$KeyLength='ec-256',
        [Parameter(ParameterSetName='ImportKey',Mandatory)]
        [string]$KeyFile,
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [Alias('Name')]
        [string]$ID,
        [switch]$AcceptTOS,
        [switch]$Force,
        [string]$ExtAcctKID,
        [string]$ExtAcctHMACKey,
        [ValidateSet('HS256','HS384','HS512')]
        [string]$ExtAcctAlgorithm = 'HS256',
        [switch]$UseAltPluginEncryption,
        [Parameter(ValueFromRemainingArguments=$true)]
        $ExtraParams
    )

    # make sure we have a server configured
    if (-not ($server = Get-PAServer)) {
        try { throw "No ACME server configured. Run Set-PAServer first." }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # make sure the external account binding parameters were specified if this ACME
    # server requires them.
    if ($server.meta -and $server.meta.externalAccountRequired -and
        (-not $ExtAcctKID -or -not $ExtAcctHMACKey))
    {
        try { throw "The current ACME server requires external account credentials to create a new ACME account. Please run New-PAAccount with the ExtAcctKID and ExtAcctHMACKey parameters." }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    # try to decode the HMAC key if specified
    if ($ExtAcctHMACKey) {
        $keyBytes = ConvertFrom-Base64Url $ExtAcctHMACKey -AsByteArray
        $hmacKey = switch ($ExtAcctAlgorithm) {
            'HS256' { [Security.Cryptography.HMACSHA256]::new($keyBytes); break; }
            'HS384' { [Security.Cryptography.HMACSHA384]::new($keyBytes); break; }
            'HS512' { [Security.Cryptography.HMACSHA512]::new($keyBytes); break; }
        }
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

    if ('Generate' -eq $PSCmdlet.ParameterSetName) {

        # There's a chance we may be creating effectively a duplicate account. So check
        # for confirmation if there's already one with the same contacts and keylength.
        if (-not $Force) {
            $accts = @(Get-PAAccount -List -Refresh -Contact $Contact -KeyLength $KeyLength -Status 'valid')
            if ($accts.Count -gt 0) {
                if (-not $PSCmdlet.ShouldContinue("Do you wish to duplicate?",
                    "An account exists with matching contacts and key length.")) { return }
            }
        }

        Write-Debug "Creating new $KeyLength account with contact: $($Contact -join ', ')"

        # create the account key
        $acctKey = New-PAKey $KeyLength

    } else { # ImportKey parameter set

        try {
            $kLength = [string]::Empty
            $acctKey = New-PAKey -KeyFile $KeyFile -ParsedLength ([ref]$kLength)
            $KeyLength = $kLength
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

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
        alg   = $alg
        jwk   = ($acctKey | ConvertTo-Jwk -PublicOnly)
        nonce = $script:Dir.nonce
        url   = $script:Dir.newAccount
    }

    # init the payload
    $payload = @{}
    if ($Contact.Count -gt 0) {
        $payload.contact = $Contact
    }
    if ($AcceptTOS) {
        $payload.termsOfServiceAgreed = $true
    }

    # add external account binding if specified
    if ($ExtAcctKID -and $ExtAcctHMACKey) {

        $eabHeader = @{
            alg = $ExtAcctAlgorithm
            kid = $ExtAcctKID
            url = $script:Dir.newAccount
        }

        $eabPayload = $header.jwk | ConvertTo-Json -Depth 5 -Compress

        $payload.externalAccountBinding =
            New-Jws $hmacKey $eabHeader $eabPayload | ConvertFrom-Json
    }

    # convert it to json
    $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

    # send the request
    try {
        $response = Invoke-ACME $header $payloadJson -Key $acctKey -EA Stop
    } catch { $PSCmdlet.ThrowTerminatingError($_) }

    # grab the Location header
    if ($response.Headers.ContainsKey('Location')) {
        $location = $response.Headers['Location'] | Select-Object -First 1
    } else {
        try { throw 'No Location header found in newAccount output' }
        catch { $PSCmdlet.ThrowTerminatingError($_) }
    }

    $respObj = $response.Content | ConvertFrom-Json

    # Before RFC8555 was finalized, LE/Boulder used to return the raw account ID value as a
    # property in the JSON output for new account requests. But the finalized RFC 8555 does
    # not require this and Boulder will be removing it. But it's still a useful value to have
    # as a simpler identifier/name for referencing accounts than a full URL. So if it's not
    # returned and the user didn't provide an explicit ID value to use, we're going to try
    # and parse it from the location header. This may come back to haunt us if other ACME
    # providers use different location schemes in the future.

    if (-not $respObj.ID) {
        # https://acme-staging-v02.api.letsencrypt.org/acme/acct/xxxxxxxx
        # https://acme-v02.api.letsencrypt.org/acme/acct/xxxxxxxx
        $fallbackID = ([Uri]$location).Segments[-1]
    } else {
        $fallbackID = $respObj.ID.ToString()
    }

    # if an explicit ID was provided, make sure it doesn't conflict with
    # another account
    if ($ID) {
        if (Get-PAAccount $ID) {
            Write-Warning "Account ID '$ID' is already in use. Falling back to the default ID value."
            $ID = $fallbackID
        }
    } else {
        $ID = $fallbackID
    }

    # build the return value
    $acct = [pscustomobject]@{
        PSTypeName = 'PoshACME.PAAccount'
        id = $ID
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
        sskey = $null
        Folder = Join-Path $server.Folder $ID
    }

    # add a new AES key if specified
    if ($UseAltPluginEncryption) {
        $acct.sskey = New-AesKey
    }

    # save it to memory and disk
    $acct.id | Out-File (Join-Path $server.Folder 'current-account.txt') -Force -EA Stop
    $script:Acct = $acct
    if (-not (Test-Path $acct.Folder -PathType Container)) {
        New-Item -ItemType Directory -Path $acct.Folder -Force -EA Stop | Out-Null
    }
    $acct | Select-Object -Exclude id,Folder | ConvertTo-Json -Depth 5 | Out-File (Join-Path $acct.Folder 'acct.json') -Force -EA Stop

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

    .PARAMETER KeyFile
        The path to an existing EC or RSA private key file. This will attempt to create the account using the specified key as the ACME account key. This can be used to recover/import an existing ACME account if one is already associated with the key.

    .PARAMETER ID
        The name of the ACME acccount.

    .PARAMETER AcceptTOS
        If not specified, the ACME server will throw an error with a link to the current Terms of Service. Using this switch indicates acceptance of those Terms of Service and is required for successful account creation.

    .PARAMETER Force
        If specified, confirmation prompts that may have been generated will be skipped.

    .PARAMETER ExtAcctKID
        The external account key identifier supplied by the CA. This is required for ACME CAs that require external account binding.

    .PARAMETER ExtAcctHMACKey
        The external account HMAC key supplied by the CA and encoded as Base64Url. This is required for ACME CAs that require external account binding.

    .PARAMETER ExtAcctAlgorithm
        The HMAC algorithm to use. Defaults to 'HS256'.

    .PARAMETER UseAltPluginEncryption
        If specified, the account will be configured to use a randomly generated AES key to encrypt sensitive plugin parameters on disk instead of using the OS's native encryption methods. This can be useful if the config is being shared across systems or platforms. You can revert to OS native encryption using -UseAltPluginEncryption:$false.

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

    .Example
        New-PAAccount -KeyFile .\mykey.key -AcceptTOS

        Create a new account using a pre-generated private key file.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAccount

    .LINK
        Set-PAAccount

    #>
}
