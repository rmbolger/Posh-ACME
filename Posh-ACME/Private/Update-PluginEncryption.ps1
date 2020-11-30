function Update-PluginEncryption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ID,
        [string]$NewKey
    )

    Begin {
        # make sure we have a server configured
        if (!(Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }
    }

    Process {

        # set the specified account as current and prepare to revert when we're done
        $revertToAccount = Get-PAAccount
        Set-PAAccount $ID

        # grab a copy of all the orders and their associated plugins/args
        $orderData = @(Get-PAOrder -List |
            Select-Object MainDomain,
                Plugin,
                @{L='PluginArgs';E={Get-PAPluginArgs $_.MainDomain}})
        Write-Debug "Order data found for $($orderData.Count) orders."

        # update and save the account with the new key
        if ($NewKey) {
            Write-Debug "Saving account $ID json with new sskey."
            $script:Acct | Add-Member 'sskey' $NewKey -Force
        } else {
            Write-Debug "Saving account $ID json with null sskey."
            $script:Acct | Add-Member 'sskey' $null -Force
        }
        $acctFolder = Join-Path (Get-DirFolder) $ID
        $script:Acct | ConvertTo-Json -Depth 5 | Out-File (Join-Path $acctFolder 'acct.json') -Force -EA Stop

        # re-export all the plugin args
        if ($orderData.Count -gt 0) {
            Write-Debug ($orderData | ConvertTo-Json -Depth 5)
            $orderData | ForEach-Object {
                Export-PluginArgs $_.MainDomain -Plugin $_.Plugin -PluginArgs $_.PluginArgs -IgnoreExisting
            }
        }

        # revert the active account if necessary
        if ($revertToAccount -and $revertToAccount.id -ne $ID) {
            Write-Debug "Reverting to previously active account"
            Set-PAAccount $revertToAccount.id
        }
    }
}
