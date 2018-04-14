function Get-PAAccount {
    [OutputType('PoshACME.PAAccount')]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ID,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [switch]$Refresh
    )

    Begin {
        # make sure we have a server configured
        if (!(Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }
    }

    Process {

        # List mode
        if ('List' -eq $PSCmdlet.ParameterSetName) {

            # update from the server first if requested
            if ($Refresh) {
                Get-PAAccount -List | Where-Object { $_.status -ne 'deactivated' } | Update-PAAccount
            }

            # read the contents of each accounts's acct.json
            Write-Verbose "Loading PAAccount list from disk"
            $rawFiles = Get-ChildItem "$($script:DirFolder)\*\acct.json" | Get-Content -Raw
            $rawFiles | ConvertFrom-Json | Sort-Object id | ForEach-Object {

                    # insert the type name so it displays properly
                    $_.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

                    # send the result to the pipeline
                    Write-Output $_
            }

        # Specific mode
        } else {

            if ($ID) {

                # build the path to acct.json
                $acctFile = Join-Path $script:DirFolder $ID
                $acctFile = Join-Path $acctFile 'dir.json'

                # check if it exists
                if (Test-Path $acctFile -PathType Leaf) {
                    Write-Verbose "Loading PAAccount from disk"
                    $acct = Get-ChildItem $acctFile | Get-Content -Raw | ConvertFrom-Json
                    $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
                } else {
                    Write-Warning "Unable to find cached PAAccount info for ID $ID."
                    return $null
                }

            } else {
                # just use the current one
                Write-Verbose "Loading PAAccount from memory"
                $acct = $script:Acct
            }

            if ($acct -and $Refresh) {

                # update and then recurse to return the updated data
                Update-PAAccount $acct.id
                return (Get-PAAccount $acct.id)

            } else {

                # just return whatever we've got
                return $acct
            }
        }
    }





    <#
    .SYNOPSIS
        Get ACME account details.

    .DESCRIPTION
        Returns the details for one or more ACME accounts previously created such as Email contacts, and key length.

    .PARAMETER ID
        The account id value as returned by the ACME server.

    .PARAMETER List
        If specified, the details for all accounts will be returned.

    .PARAMETER Refresh
        If specified, any account details returned will be freshly queried from the ACME server (excluding deactivated accounts). Otherwise, cached details will be returned.

    .EXAMPLE
        Get-PAAccount

        Get cached ACME account details for the currently selected account.

    .EXAMPLE
        Get-PAAccount -ID 1234567

        Get cached ACME account details for the specified account ID.

    .EXAMPLE
        Get-PAAccount -List

        Get all cached ACME account details.

    .EXAMPLE
        Get-PAAccount -Refresh

        Get fresh ACME account details for the currently selected account.

    .EXAMPLE
        Get-PAAccount -List -Refresh

        Get fresh ACME account details for all (non-deactivated) accounts.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Set-PAAccount

    .LINK
        New-PAAccount

    #>
}
