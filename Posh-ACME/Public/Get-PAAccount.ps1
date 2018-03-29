function Get-PAAccount {
    [CmdletBinding()]
    param(
        [switch]$List
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    if ($List) {
        # read the contents of each accounts's acct.json
        Get-Content "$($script:CurrentDirFolder)\*\acct.json" -Raw |
            ConvertFrom-Json | Sort-Object id | ForEach-Object {
                $_.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
                Write-Output $_
            }
    } else {
        $script:CurrentAccount
    }

}