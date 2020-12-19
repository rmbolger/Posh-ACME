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
        if ($revertToAccount -and $revertToAccount.id -ne $ID) {
            Write-Debug "Temporarily switching to account '$ID'"
            Set-PAAccount -ID $ID
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

        # update and save the account with the new key
        if ($NewKey) {
            Write-Debug "Saving account $ID json with new sskey."
            $script:Acct | Add-Member 'sskey' $NewKey -Force
        } else {
            Write-Debug "Saving account $ID json with null sskey."
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

        # revert the active account if necessary
        if ($revertToAccount -and $revertToAccount.id -ne $ID) {
            Write-Debug "Reverting to previously active account '$($revertToAccount.id)'"
            Set-PAAccount -ID $revertToAccount.id
        }
    }
}
