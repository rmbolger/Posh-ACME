function Update-PluginEncryption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$ID,
        [string]$NewKey
    )

    Begin {
        # make sure we have a server configured
        if (-not ($server = Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }
    }

    Process {

        # set the specified account as current and prepare to revert when we're done
        $revertToAccount = Get-PAAccount
        Set-PAAccount -ID $ID

        # grab a copy of all the orders
        $orders = Get-PAOrder -List
        Write-Debug "Order data found for $($orders.Count) orders."

        # update and save the account with the new key
        if ($NewKey) {
            Write-Debug "Saving account $ID json with new sskey."
            $script:Acct | Add-Member 'sskey' $NewKey -Force
        } else {
            Write-Debug "Saving account $ID json with null sskey."
            $script:Acct | Add-Member 'sskey' $null -Force
        }
        $acctFile = Join-Path $server.Folder "$ID\acct.json"
        $script:Acct | Select-Object -Exclude id,Folder | ConvertTo-Json -Depth 5 |
            Out-File $acctFile -Force -EA Stop

        # re-export all the plugin args
        $orders | ForEach-Object {
            $pArgs = $_ | Get-PAPluginArgs
            Write-Debug "Re-exporting plugin args for order '$($_.Name)' with plugins $($_.Plugin -join ',') and data $($pArgs | ConvertTo-Json -Depth 5)"
            Export-PluginArgs -Order $_ -PluginArgs $pArgs -IgnoreExisting
        }

        # revert the active account if necessary
        if ($revertToAccount -and $revertToAccount.id -ne $ID) {
            Write-Debug "Reverting to previously active account"
            Set-PAAccount -ID $revertToAccount.id
        }
    }
}
