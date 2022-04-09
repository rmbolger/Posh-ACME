function Set-PAAccount {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='Edit')]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [Alias('Name')]
        [string]$ID,
        [Parameter(ParameterSetName='Edit',Position=1)]
        [string[]]$Contact,
        [Parameter(ParameterSetName='Edit')]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$NewName,
        [Parameter(ParameterSetName='Edit')]
        [switch]$UseAltPluginEncryption,
        [Parameter(ParameterSetName='Edit')]
        [switch]$ResetAltPluginEncryption,
        [Parameter(ParameterSetName='Edit')]
        [switch]$Deactivate,
        [Parameter(ParameterSetName='Edit')]
        [switch]$Force,
        [Parameter(ParameterSetName='Rollover',Mandatory)]
        [Parameter(ParameterSetName='RolloverImportKey',Mandatory)]
        [switch]$KeyRollover,
        [Parameter(ParameterSetName='Rollover')]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [Alias('AccountKeyLength')]
        [string]$KeyLength='ec-256',
        [Parameter(ParameterSetName='RolloverImportKey',Mandatory)]
        [string]$KeyFile,
        [switch]$NoSwitch
    )

    Begin {
        # make sure we have a server configured
        if (-not ($server = Get-PAServer)) {
            try { throw "No ACME server configured. Run Set-PAServer first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
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

        # There are 3 types of calls the user might be making here.
        # - account switch
        # - account switch and modification
        # - modification only (possibly bulk via pipeline)
        # The default is to switch accounts. So we have a -NoSwitch parameter to
        # indicate a non-switching modification. But there's a chance they could forget
        # to use it for a bulk update. For now, we'll just let it happen and switch
        # to whatever account came through the pipeline last.

        # make sure there's an account associated with the specified ID or
        # a current account
        if ($ID) {
            if (-not ($acct = Get-PAAccount -ID $ID)) {
                Write-Warning "Specified account ID ($ID) was not found. No changes made."
                return
            }
            # check if we're switching
            $oldAcct = Get-PAAccount
            if ($oldAcct -and $oldAcct.id -eq $acct.id) {
                $NoSwitch = $true
            }
        } else {
            if (-not ($acct = Get-PAAccount)) {
                try { throw "No ACME account configured. Run New-PAAccount or specify an account ID." }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
            $NoSwitch = $true
        }

        # switch the current account unless told not to or it's not changing
        if (-not $NoSwitch) {
            Write-Debug "Switching to account $($acct.id)"

            # save it as current
            $acct.id | Out-File (Join-Path $server.Folder 'current-account.txt') -Force -EA Stop

            # reload the cache from disk
            Import-PAConfig -Level 'Account'

            # grab a local reference to the newly current account
            $acct = Get-PAAccount
        }

        $saveAccount = $false

        # deal with encryption changes
        if ('UseAltPluginEncryption' -in $PSBoundParameters.Keys -or $ResetAltPluginEncryption) {

            $encSplat = @{
                Enable = $UseAltPluginEncryption.IsPresent
                Reset = $ResetAltPluginEncryption.IsPresent
            }
            if ($encSplat.Reset) { $encSplat.Enable = $true }
            $acct | Set-AltPluginEncryption @encSplat
        }

        # deal with server side changes
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
                if (-not $Contact) {
                    $payload.contact = @()
                } else {
                    $payload.contact = $Contact
                }
            }
            if ($Deactivate) {
                if (-not $Force) {
                    if (-not $PSCmdlet.ShouldContinue("Are you sure you wish to deactivate account $($acct.id)?",
                    "Deactivating an account is irreversible and will prevent modifications or renewals for associated orders and certificates.")) {
                        Write-Verbose "Deactivation aborted for account $($acct.id)."
                        return
                    }
                }
                $payload.status = 'deactivated'
            }

            # convert it to json
            $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress

            # send the request
            try {
                $response = Invoke-ACME $header $payloadJson $acct -EA Stop
            } catch { throw }

            $respObj = ($response.Content | ConvertFrom-Json)

            # update the things that could have changed
            $acct.status = $respObj.status
            $acct.contact = $respObj.contact

            $saveAccount = $true
        }

        # deal with key rollover
        if ($KeyRollover) {

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
            } | ConvertTo-Json -Depth 5 -Compress

            # build the outer payload by creating a signed JWS from
            # the inner header/payload and new key
            $payloadJson = New-Jws $newKey $innerHead $innerPayloadJson -NoHeaderValidation

            # send the request
            try {
                Invoke-ACME $header $payloadJson $acct -EA Stop | Out-Null

                # https://datatracker.ietf.org/doc/html/rfc8555#section-7.3.5
                # Success is indicated by an HTTP 200 response. No response body
                # is required even though Let's Encrypt sends one.

                # So if we haven't caught an error, update the account with the
                # new key
                $acct.key = $newKey | ConvertTo-Jwk
                $acct.alg = $alg
                $acct.KeyLength = $KeyLength

                $saveAccount = $true

            } catch { throw }

        }

        # Deal with potential name change
        if ($NewName -and $NewName -ne $acct.id) {

            $newFolder = Join-Path $server.Folder $NewName
            if (Test-Path $newFolder) {
                Write-Error "Failed to rename PAAccount $($acct.id). The path '$newFolder' already exists."
            } else {
                # rename the dir folder
                Write-Debug "Renaming $($acct.id) account folder to $newFolder"
                try {
                    Rename-Item $acct.Folder $newFolder -EA Stop

                    # update the id/Folder in memory
                    $acct.id = $NewName
                    $acct.Folder = $newFolder

                    # update the current account ref if necessary
                    $curAcctFile = (Join-Path $server.Folder 'current-account.txt')
                    if ($acct.id -ne (Get-Content $curAcctFile -EA Ignore)) {
                        Write-Debug "Updating current-account.txt"
                        $NewName | Out-File $curAcctFile -Force -EA Stop
                    }

                    $saveAccount = $true
                }
                catch {
                    Write-Error $_
                }
            }
        }

        if ($saveAccount) {
            # save it to disk
            $acctFile = Join-Path $server.Folder "$($acct.id)\acct.json"
            $acct | Select-Object -Property * -ExcludeProperty id,Folder |
                ConvertTo-Json -Depth 5 |
                Out-File $acctFile -Force -EA Stop

            # reload config from disk
            Import-PAConfig -Level Account
        }

    }
}
