function Get-PAAccount {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAccount')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$ID,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List,
        [Parameter(ParameterSetName='List')]
        [ValidateSet('valid','deactivated','revoked')]
        [string]$Status,
        [Parameter(ParameterSetName='List')]
        [string[]]$Contact,
        [Parameter(ParameterSetName='List')]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [Alias('AccountKeyLength')]
        [string[]]$KeyLength,
        [switch]$Refresh,
        [Parameter(ValueFromRemainingArguments=$true)]
        $ExtraParams
    )

    Begin {
        # make sure we have a server configured
        if (!(Get-PAServer)) {
            throw "No ACME server configured. Run Set-PAServer first."
        }

        # make sure the Contact emails have a "mailto:" prefix
        # this may get more complex later if ACME servers support more than email based contacts
        if ($Contact.Count -gt 0) {
            0..($Contact.Count-1) | ForEach-Object {
                if ($Contact[$_] -notlike 'mailto:*') {
                    $Contact[$_] = "mailto:$($Contact[$_])"
                }
            }
        }
    }

    Process {

        # List mode
        if ('List' -eq $PSCmdlet.ParameterSetName) {

            # update from the server first if requested
            if ($Refresh) {
                Write-Debug "Refreshing valid accounts"
                Get-PAAccount -List -Status 'valid' | Update-PAAccount
            }

            # read the contents of each accounts's acct.json
            Write-Debug "Loading PAAccount list from disk"
            $rawFiles = Get-ChildItem "$($script:DirFolder)\*\acct.json" | Get-Content -Raw
            $accts = $rawFiles | ConvertFrom-Json | Sort-Object id | ForEach-Object {

                    # insert the type name and send the results to the pipeline
                    $_.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
                    $_
            }

            # filter by Status if specified
            if ('Status' -in $PSBoundParameters.Keys) {
                $accts = $accts | Where-Object { $_.status -eq $Status }
            }

            # filter by KeyLength if specified
            if ('KeyLength' -in $PSBoundParameters.Keys) {
                $accts = $accts | Where-Object { $_.KeyLength -eq $KeyLength }
            }

            # filter by Contact if specified
            if ('Contact' -in $PSBoundParameters.Keys) {
                if (!$Contact) {
                    $accts = $accts | Where-Object { $_.contact.count -eq 0 }
                } else {
                    $accts = $accts | Where-Object { $_.contact.count -gt 0 -and $null -eq (Compare-Object $Contact $_.contact) }
                }
            }

            return $accts

        # Specific mode
        } else {

            if ($ID) {

                # build the path to acct.json
                $acctFolder = Join-Path $script:DirFolder $ID
                $acctFile = Join-Path $acctFolder 'acct.json'

                # check if it exists
                if (Test-Path $acctFile -PathType Leaf) {
                    Write-Debug "Loading PAAccount from disk"
                    $acct = Get-ChildItem $acctFile | Get-Content -Raw | ConvertFrom-Json
                    $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')
                } else {
                    return $null
                }

            } else {
                # just use the current one
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
        Returns details such as Email, key length, and status for one or more ACME accounts previously created.

    .PARAMETER ID
        The account id value as returned by the ACME server.

    .PARAMETER List
        If specified, the details for all accounts will be returned.

    .PARAMETER Status
        A Status string to filter the list of accounts with.

    .PARAMETER Contact
        One or more email addresses to filter the list of accounts with. Returned accounts must match exactly (not including the order).

    .PARAMETER KeyLength
        The type and size of private key to filter the list of accounts with. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'.

    .PARAMETER Refresh
        If specified, any account details returned will be freshly queried from the ACME server (excluding deactivated accounts). Otherwise, cached details will be returned.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

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

        Get fresh ACME account details for all accounts.

    .EXAMPLE
        Get-PAAccount -List -Contact user1@example.com

        Get cached ACME account details for all accounts that have user1@example.com as the only contact.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Set-PAAccount

    .LINK
        New-PAAccount

    #>
}
