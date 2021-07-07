function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$BegetCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Beget has a weird issue with their API where you can't retrieve the existing records
    # for a DNS sub-zone unless it also has a sub-domain defined for it. But you can't create
    # sub-domains for things that start with _acme-challenge (presumably they don't like the
    # first char underscore). So if the initial call to dns/getData fails, we're just going to
    # blindly replace the existing records for that sub-zone (which should still work) and
    # hope for the best.

    # Because the dns/changeRecords call is more of a "replace all records for this name" type
    # of call, we're going to queue the changes for each unique name and then wait to
    # do the replace when Save-DnsTxt is called.

    # setup a module variable to queue the changes in
    if (!$script:BegetRecordChanges) { $script:BegetRecordChanges = @{} }

    # check for the record in the cache
    if ($script:BegetRecordChanges.ContainsKey($RecordName)) {
        $changes = $script:BegetRecordChanges.$RecordName
    }

    if (-not $changes) {
        # try to get the existing record data for this FQDN
        $body = @{
            login = $BegetCredential.UserName
            passwd = $BegetCredential.GetNetworkCredential().Password
            input_format = 'json'
            input_data = @{fqdn=$RecordName} | ConvertTo-Json -Compress
        }
        $queryParams = @{
            Uri = 'https://api.beget.com/api/dns/getData'
            Method = 'POST'
            Body = $body
            Verbose = $false
            ErrorAction = 'Stop'
        }
        try {
            Write-Debug "POST $($queryParams.Uri)`n$($body.input_data)"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch { throw }

        if ($response.answer.status -eq 'error') {
            Write-Verbose "No existing records found for $RecordName. This is expected for sub-zones that don't have a corresponding sub-domain."
        } else {
            # save the existing values for all records
            $changes = $response.answer.result.records
        }
    }

    if ($changes -and $changes.'TXT' -and
        ($TxtValue -in $changes.'TXT'.value -or $TxtValue -in $changes.'TXT'.txtdata))
    {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    if (-not $changes) {
        # start a new record set
        $changes = @{
            'TXT' = @(
                @{ value = $TxtValue }
            )
        }
    } elseif (-not $changes.'TXT') {
        # add a new TXT record
        $changes.'TXT' = @(
            @{ value = $TxtValue }
        )
    } elseif ($TxtValue -notin $changes.'TXT'.value -and $TxtValue -notin $changes.'TXT'.txtdata) {
        # add a new value
        $changes.'TXT' += @{ value = $TxtValue }
    }

    Write-Verbose "Adding $RecordName with value $TxtValue."
    Write-Debug "Queued $($changes | ConvertTo-Json -Compress -Dep 10)"
    $script:BegetRecordChanges.$RecordName = $changes


    <#
    .SYNOPSIS
        Add a DNS TXT record to Beget.com

    .DESCRIPTION
        Description for Beget.com

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -BegetCredential (Get-Credential)

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$BegetCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Beget has a weird issue with their API where you can't retrieve the existing records
    # for a DNS sub-zone unless it also has a sub-domain defined for it. But you can't create
    # sub-domains for things that start with _acme-challenge (presumably they don't like the
    # first char underscore). So if the initial call to dns/getData fails, we're just going to
    # blindly replace the existing records for that sub-zone (which should still work) and
    # hope for the best.

    # Because the dns/changeRecords call is more of a "replace all records for this name" type
    # of call, we're going to queue the changes for each unique name and then wait to
    # do the replace when Save-DnsTxt is called.

    # setup a module variable to queue the changes in
    if (!$script:BegetRecordChanges) { $script:BegetRecordChanges = @{} }

    # check for the record in the cache
    if ($script:BegetRecordChanges.ContainsKey($RecordName)) {
        $changes = $script:BegetRecordChanges.$RecordName
    }

    if (-not $changes) {
        # try to get the existing record data for this FQDN
        $body = @{
            login = $BegetCredential.UserName
            passwd = $BegetCredential.GetNetworkCredential().Password
            input_format = 'json'
            input_data = @{fqdn=$RecordName} | ConvertTo-Json -Compress
        }
        $queryParams = @{
            Uri = 'https://api.beget.com/api/dns/getData'
            Method = 'POST'
            Body = $body
            Verbose = $false
            ErrorAction = 'Stop'
        }
        try {
            Write-Debug "POST $($queryParams.Uri)`n$($body.input_data)"
            $response = Invoke-RestMethod @queryParams @script:UseBasic
        } catch { throw }

        if ($response.answer.status -eq 'error') {
            Write-Verbose "No existing records found for $RecordName. This is expected for sub-zones that don't have a corresponding sub-domain."
        } else {
            # save the existing values for all records
            $changes = $response.answer.result.records
        }
    }

    if ($changes -and
        (-not $changes.'TXT' -or
        ($TxtValue -notin $changes.'TXT'.value -and $TxtValue -notin $changes.'TXT'.txtdata)))
    {
        # records exist for this name, but our TXT value isn't in them, so just return
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }

    if (-not $changes) {
        # no records could mean that we simply can't get the records because of the whole
        # API weirdness thing with sub-zones. But we can still submit a request to wipe
        # the TXT records for this name.
        Write-Verbose "Deleting all TXT records for $RecordName"
        $changes = @{ 'TXT' = @() }
    }
    else {
        # remove the current value from the set
        Write-Verbose "Removing $RecordName with value $TxtValue."
        $changes.'TXT' = @($changes.'TXT' | Where-Object {
            $_.value -ne $TxtValue -and $_.txtdata -ne $TxtValue
        })
    }

    Write-Debug "Queued $($changes | ConvertTo-Json -Compress -Dep 10)"
    $script:BegetRecordChanges.$RecordName = $changes



    <#
    .SYNOPSIS
        Remove a DNS TXT record from Beget.com

    .DESCRIPTION
        Description for Beget.com

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -BegetCredential (Get-Credential)

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]$BegetCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $recNames = @()

    # check for queued changes
    if ($script:BegetRecordChanges -and $script:BegetRecordChanges.Keys.Count -gt 0) {
        $recNames = @($script:BegetRecordChanges.Keys)
    }

    $recNames | ForEach-Object {

        $recName = $_
        $recs = $script:BegetRecordChanges.$_
        Write-Verbose "Committing changes for $recName"

        $changeParams = @{
            Uri = ' https://api.beget.com/api/dns/changeRecords'
            Method = 'POST'
            Body = @{
                login = $BegetCredential.UserName
                passwd = $BegetCredential.GetNetworkCredential().Password
                input_format = 'json'
                input_data = @{
                    fqdn = $recName
                    records = $recs
                } | ConvertTo-Json -Compress -Depth 10
            }
            Verbose = $false
            ErrorAction = 'Stop'
        }

        try {
            Write-Debug "POST $($changeParams.Uri)`n$($changeParams.Body.input_data)"
            $response = Invoke-RestMethod @changeParams @script:UseBasic
        } catch { throw }


        if ($response.answer.status -eq 'error') {

            if ($response.answer.errors[0].error_text.type -eq 'INVALID_DATA_SINGLE') {
                # If we're updating a shared domain that has a forced A record, our change
                # request generates an error because the API doesn't want us overwriting it.
                # But we can just take it out of the change set and re-submit.
                Write-Debug "Retrying with no A records in change set."
                $recs.PSObject.Properties.Remove('A')
                $changeParams.Body.input_data = @{
                    fqdn = $recName
                    records = $recs
                } | ConvertTo-Json -Compress -Depth 10
                try {
                    Write-Debug "POST $($changeParams.Uri)`n$($changeParams.Body.input_data)"
                    $response = Invoke-RestMethod @changeParams @script:UseBasic
                } catch { throw }

                if ($response.answer.status -eq 'error') {
                    Write-Debug ($response.answer | ConvertTo-Json -Depth 10)
                    $script:BegetRecordChanges.Remove($recName)
                    throw "Error updating $($recName): $($response.answer.errors | ConvertTo-Json -Dep 10 -Compress)"
                }

            } else {
                Write-Debug ($response.answer | ConvertTo-Json -Depth 10)
                $script:BegetRecordChanges.Remove($recName)
                throw "Error updating $($recName): $($response.answer.errors | ConvertTo-Json -Dep 10 -Compress)"
            }
        }

        # wipe the changes from the queue
        $script:BegetRecordChanges.Remove($recName)

    }



    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to Beget.com

    .DESCRIPTION
        Description for Beget.com

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt -BegetCredential (Get-Credential)

        Commits changes for pending DNS TXT record modifications.
    #>
}

############################
# Helper Functions
############################

# API Docs:
# https://beget.com/en/kb/api/beget-api
