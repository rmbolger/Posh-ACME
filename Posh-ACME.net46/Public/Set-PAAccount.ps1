function Set-PAAccount {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='Normal')]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ID,
        [Parameter(ParameterSetName='Normal',Position=1)]
        [string[]]$Contact,
        [Parameter(ParameterSetName='Normal')]
        [switch]$Deactivate,
        [Parameter(ParameterSetName='Normal')]
        [switch]$Force,
        [Parameter(ParameterSetName='Rollover',Mandatory)]
        [Parameter(ParameterSetName='RolloverImportKey',Mandatory)]
        [switch]$KeyRollover,
        [Parameter(ParameterSetName='Rollover')]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [Alias('AccountKeyLength')]
        [string]$KeyLength='2048',
        [Parameter(ParameterSetName='RolloverImportKey',Mandatory)]
        [string]$KeyFile,
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

            if ($null -eq $acct) {
                Write-Warning "Specified account ID ($ID) was not found. No changes made."
                return
            }

        } elseif (!$script:Acct -or ($ID -and ($ID -ne $script:Acct.id))) {
            # This is a definite account switch

            # refresh the cached copy
            Update-PAAccount $ID

            Write-Debug "Switching to account $ID"

            # save it as current
            $ID | Out-File (Join-Path (Get-DirFolder) 'current-account.txt') -Force -EA Stop

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
                if (!$Force) {
                    if (!$PSCmdlet.ShouldContinue("Are you sure you wish to deactivate account $($acct.id)?",
                    "Deactivating an account is irreversible and will prevent modifications or renewals for associated orders and certificates.")) {
                        Write-Verbose "Modification aborted for account $($acct.id)."
                        return
                    }
                }
                $payload.status = 'deactivated'
            }

            # convert it to json
            $payloadJson = $payload | ConvertTo-Json -Compress

            # send the request
            try {
                $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            } catch { throw }
            Write-Debug "Response: $($response.Content)"

            $respObj = ($response.Content | ConvertFrom-Json)

            # update the things that could have changed
            $acct.status = $respObj.status
            $acct.contact = $respObj.contact

            # save it to disk
            $acctFolder = Join-Path (Get-DirFolder) $acct.id
            $acct | ConvertTo-Json | Out-File (Join-Path $acctFolder 'acct.json') -Force -EA Stop

        } elseif ($KeyRollover) {

            # We've been asked to rollover the account key which effectively means replace it
            # with a new one. The spec describes the process in the following link.
            # https://tools.ietf.org/html/rfc8555#section-7.3.5

            # build the standard outer header
            $header = @{
                alg   = $acct.alg;
                kid   = $acct.location;
                nonce = $script:Dir.nonce;
                url   = $script:Dir.keyChange;
            }

            if ($KeyFile) {
                # attempt to use the specified key as the new account key
                try {
                    $kLength = [string]::Empty
                    $newKey = New-PAKey -KeyFile $KeyFile -ParsedLength ([ref]$kLength)
                    $KeyLength = $kLength
                }
                catch { $PSCmdlet.ThrowTerminatingError($_) }

            } else {
                # generate a new account key
                $newKey = New-PAKey $KeyLength
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

            # build the inner header
            $innerHead = @{
                alg  = $alg;
                jwk  = ($newKey | ConvertTo-Jwk -PublicOnly);
                url  = $script:Dir.keyChange;
            }

            # build the inner payload
            $innerPayloadJson = @{
                account = $acct.location;
                oldKey  = $acct.Key | ConvertFrom-Jwk | ConvertTo-Jwk -PublicOnly
            } | ConvertTo-Json -Compress

            # build the outer payload by creating a signed JWS from
            # the inner header/payload and new key
            $payloadJson = New-Jws $newKey $innerHead $innerPayloadJson -NoHeaderValidation

            # send the request
            try {
                $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            } catch { throw }
            Write-Debug "Response: $($response.Content)"

            $respObj = ($response.Content | ConvertFrom-Json)
            if ($respObj.status -eq 'valid') {
                # update the account with the new key
                $acct.key = $newKey | ConvertTo-Jwk
                $acct.alg = $alg
                $acct.KeyLength = $KeyLength

                # save it to disk
                $acctFolder = Join-Path (Get-DirFolder) $acct.id
                $acct | ConvertTo-Json | Out-File (Join-Path $acctFolder 'acct.json') -Force -EA Stop
            }
        }

    }





    <#
    .SYNOPSIS
        Set the current ACME account and/or update account details.

    .DESCRIPTION
        This function allows you to switch between ACME accounts for a particular server. It also allows you to update the contact information associated with an account, deactivate the account, or replace the account key with a new one.

    .PARAMETER ID
        The account id value as returned by the ACME server. If not specified, the function will attempt to use the currently active account.

    .PARAMETER Contact
        One or more email addresses to associate with this account. These addresses will be used by the ACME server to send certificate expiration notifications or other important account notices.

    .PARAMETER Deactivate
        If specified, a request will be sent to the associated ACME server to deactivate the account. Clients may wish to do this if the account key is compromised or decommissioned.

    .PARAMETER Force
        If specified, confirmation prompts for account deactivation will be skipped.

    .PARAMETER KeyRollover
        If specified, generate a new account key and replace the current one with it. Clients may choose to do this to recover from a key compromise or proactively mitigate the impact of an unnoticed key compromise.

    .PARAMETER KeyLength
        The type and size of private key to use. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to '2048'.

    .PARAMETER KeyFile
        The path to an existing EC or RSA private key file. This will attempt to use the specified key as the new ACME account key.

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

    .EXAMPLE
        Set-PAAccount -KeyRollover -KeyLength ec-384

        Replace the current account key with a new ECC key using P-384 curve.

    .EXAMPLE
        Set-PAAccount -KeyRollover -KeyFile .\mykey.key

        Replace the current account key with a pre-generated private key.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAAccount

    .LINK
        New-PAAccount

    #>
}
