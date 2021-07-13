function Update-PAAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string]$ID
    )

    Begin {
        # make sure we have a server configured
        if (-not ($server = Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }
    }

    Process {

        # make sure there's an ID or current account
        if (-not $ID -and -not ($acct = Get-PAAccount)) {
            Write-Warning "No ACME account configured. Run Set-PAAccount or specify an ID."
            return
        }

        # get a reference to the specified account if it exists
        if ($ID -and $ID -ne $acct.id) {
            if (-not ($acct = Get-PAAccount $ID)) {
                Write-Warning "Specified account id ($ID) not found. Nothing to update."
                return
            }
        }

        Write-Debug "Refreshing account $($acct.id)"

        # build the header
        $header = @{
            alg   = $acct.alg;
            kid   = $acct.location;
            nonce = $script:Dir.nonce;
            url   = $acct.location;
        }

        # send the request
        try {
            $response = Invoke-ACME $header ([String]::Empty) $acct -EA Stop
        } catch { throw }

        $respObj = $response.Content | ConvertFrom-Json

        # update the things that could have changed
        $acct | Add-Member 'status' $respObj.status -Force
        $acct | Add-Member 'contact' $respObj.contact -Force

        # save it to disk without the dynamic properties
        $acctFile = Join-Path $server.Folder "$($acct.id)\acct.json"
        $acct | Select-Object -Exclude id,Folder | ConvertTo-Json -Depth 5 | Out-File $acctFile -Force -EA Stop

    }
}
