function Get-PAAccount {
    [CmdletBinding()]
    param(
        [switch]$List,
        [switch]$Refresh
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    if ($List) {
        # read the contents of each accounts's acct.json
        Get-ChildItem "$($script:DirFolder)\*\acct.json" | Get-Content -Raw |
            ConvertFrom-Json | Sort-Object id | ForEach-Object {

                $_.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

                # update the data from the server for anything not deactivated
                if ($Refresh -and $_.status -ne 'deactivated') { Update-PAAccount $_ }
                Write-Output $_
            }
    } else {

        $acct = $script:Acct

        # update the data from the server if requested
        if ($Refresh) { Update-PAAccount $acct }

        $script:Acct
    }

}
