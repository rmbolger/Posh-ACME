function Get-PAAccount {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAccount')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [Alias('Name')]
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
        if (-not ($server = Get-PAServer)) {
            try { throw "No ACME server configured. Run Set-PAServer first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
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

            $accts = Get-ChildItem (Join-Path $server.Folder '\*\acct.json') | ForEach-Object {

                # parse the json
                $acct = $_ | Get-Content -Raw | ConvertFrom-Json

                # insert the type name
                $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

                # add the dynamic id (Name) and Folder property
                $acct | Add-Member 'id' $_.Directory.Name -Force
                $acct | Add-Member 'Folder' $_.Directory.FullName -Force

                # send the result to the pipeline
                Write-Output $acct
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
                if (-not $Contact) {
                    $accts = $accts | Where-Object { $_.contact.Count -eq 0 }
                } else {
                    $accts = $accts | Where-Object { $_.contact.Count -gt 0 -and $null -eq (Compare-Object $Contact $_.contact) }
                }
            }

            return $accts

        # Specific mode
        } else {

            if ($ID) {

                # build the path to acct.json
                $acctFolder = Join-Path $server.Folder $ID
                $acctFile = Join-Path $acctFolder 'acct.json'

                # check if it exists
                if (Test-Path $acctFile -PathType Leaf) {
                    Write-Debug "Loading PAAccount $ID from disk"
                    $acct = Get-Content $acctFile -Raw | ConvertFrom-Json
                    $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

                    # add the dynamic id (Name) and Folder property
                    $acct | Add-Member 'id' (Get-Item $acctFolder).Name -Force
                    $acct | Add-Member 'Folder' $acctFolder -Force

                } else {
                    return $null
                }

            } else {
                # just use the current one
                $acct = $script:Acct
            }

            if ($acct -and $Refresh -and $acct.status -eq 'valid') {

                # update and then recurse to return the updated data
                Update-PAAccount $acct.id
                return (Get-PAAccount $acct.id)

            } else {
                # just return whatever we've got
                return $acct
            }
        }
    }
}
