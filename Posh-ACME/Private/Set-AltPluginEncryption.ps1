function Set-AltPluginEncryption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$ID,
        [Parameter(Mandatory)]
        [switch]$Enable,
        [switch]$Reset
    )

    Begin {
        # make sure we have a server configured
        if (-not ($server = Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }

        # save the current account to revert to if necessary
        $revertToAccount = Get-PAAccount
    }

    Process {

        # set the specified account as current and prepare to revert when we're done
        if ($revertToAccount -and $revertToAccount.id -ne $ID) {
            Write-Debug "Temporarily switching to account '$ID'"
            Set-PAAccount -ID $ID
        }

        # return early if there's nothing to do
        $oldSSKey = $script:Acct.sskey
        if ($Enable -and -not $Reset -and -not [String]::IsNullOrWhiteSpace($oldSSKey)) {
            Write-Debug "AltPluginEncryption is already enabled on account '$ID'."
            return
        } elseif (-not $Enable -and [String]::IsNullOrWhiteSpace($oldSSKey)) {
            Write-Debug "AltPluginEncryption is already disabled on account '$ID'."
            return
        }

        # grab a copy of the orders and plugin args before we break
        # the ability to decrypt them
        $orderData = @(Get-PAOrder -List | ForEach-Object {
            @{
                Order = $_
                PluginArgs = ($_ | Get-PAPluginArgs)
            }
        })
        Write-Debug "Order data found for $($orderData.Count) orders."

        if ($Enable) {

            # generate a new key in case we need it
            $newSSKey = New-AesKey

            # check for vault config
            if (-not [string]::IsNullOrWhiteSpace($env:POSHACME_VAULT_NAME)) {
                try {
                    $vaultName = $env:POSHACME_VAULT_NAME

                    # make sure we have the necessary SecretManagement commands available
                    if (-not (Get-Command 'Unlock-SecretVault' -EA Ignore) -or
                        -not (Get-Command 'Get-Secret' -EA Ignore) )
                    {
                        throw "Commands associated with SecretManagement module not found. Make sure Microsoft.PowerShell.SecretManagement is installed and accessible."
                    }

                    # if a vault password is defined, explicitly unlock the vault
                    if (-not [string]::IsNullOrEmpty($env:POSHACME_VAULT_PASS)) {
                        $ssPass = ConvertTo-SecureString $env:POSHACME_VAULT_PASS -AsPlainText -Force
                        Unlock-SecretVault -Name $vaultName -Password $ssPass
                    }

                    # get or create the vault guid
                    $vaultGuid = $script:Acct.VaultGuid
                    if ([string]::IsNullOrWhiteSpace($vaultGuid)) {
                        $vaultGuid = (New-Guid).ToString().Replace('-','')
                    }

                    # build the secret name
                    if ([String]::IsNullOrEmpty($env:POSHACME_VAULT_SECRET_TEMPLATE)) {
                        $secretName = 'poshacme-{0}-sskey' -f $vaultGuid
                    } else {
                        Write-Debug "Using custom secret template: $($env:POSHACME_VAULT_SECRET_TEMPLATE)"
                        $secretName = $env:POSHACME_VAULT_SECRET_TEMPLATE -f $vaultGuid
                    }

                    # check for an existing key value
                    $oldSecret = Get-Secret -Vault $vaultName -Name $secretName -AsPlainText -EA Ignore

                    if ($Reset -or -not $oldSecret) {
                        # attempt to write a new vault key
                        Write-Debug "Attempting to add new secret '$secretName' to vault '$vaultName'."
                        Set-Secret -Vault $vaultName -Name $secretName -Secret $newSSKey -EA Stop
                        Write-Verbose "Enabling AltPluginEncryption for account '$ID' with new vault key."
                    } else {
                        # use the existing vault key
                        Write-Verbose "Enabling AltPluginEncryption for account '$ID' with existing vault key."
                        $newSSKey = $oldSecret
                    }

                    $script:Acct | Add-Member 'sskey' 'VAULT' -Force
                    $script:Acct | Add-Member 'VaultGuid' $vaultGuid -Force
                }
                catch {
                    Write-Warning "Unable to save encryption key to secret vault. $($_.Exception.Message)"

                    # just save the key onto the account
                    Write-Debug "Saving account $ID with new sskey."
                    $script:Acct | Add-Member 'sskey' $newSSKey -Force
                }
            } else {
                # just save the key onto the account
                Write-Debug "Saving account $ID with new sskey."
                $script:Acct | Add-Member 'sskey' $newSSKey -Force
            }

        } else {
            # remove the key
            Write-Verbose "Disabling AltPluginEncryption for account '$ID'"
            $script:Acct | Add-Member 'sskey' $null -Force
        }

        $acctFile = Join-Path $server.Folder "$ID\acct.json"
        $script:Acct | Select-Object -Property * -ExcludeProperty id,Folder |
            ConvertTo-Json -Depth 5 |
            Out-File $acctFile -Force -EA Stop

        # re-export all the plugin args
        $orderData | ForEach-Object {
            Write-Debug "Re-exporting plugin args for order '$($_.Order.Name)' with plugins $($_.Order.Plugin -join ',') and data $($_.PluginArgs | ConvertTo-Json -Depth 5)"
            Export-PluginArgs @_ -IgnoreExisting
        }
    }

    End {
        $curAcct = Get-PAAccount
        Write-Debug "revert id = $($revertToAccount.id), cur id = $($curAcct.id)"
        if ($revertToAccount -and
            (-not $curAcct -or ($curAcct.id -ne $revertToAccount.id) ))
        {
            Write-Debug "Reverting to previously active account '$($revertToAccount.id)'"
            Set-PAAccount -ID $revertToAccount.id
        }
    }
}
