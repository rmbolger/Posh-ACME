function Add-DnsTxtGoDaddy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDKey,
        [Parameter(Mandatory, Position = 3)]
        [string]$GDSecret,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://api.godaddy.com/v1/domains"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v1/domains"
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    $zone = Find-GDZone -RecordName $RecordName -GDKey $GDKey -GDSecret $GDSecret
    $recShort = ($RecordName -split ".$zone")[0]

    # Get a list of existing TXT records for this record name
    try {
        $recs = Invoke-RestMethod "$apiRoot/$zone/records/TXT/$recShort" `
            -Headers $headers @script:UseBasic -EA Stop
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        # For some odd reason, the GoDaddy API doesn't have a method to add a single
        # record. The closest we can get is re-setting the set of records that match
        # a particular Type and Name. So we need to add our new record to the current
        # set of results and send that.

        # filter out the empty record that may be leftover from a previous removal
        $recs = @($recs | Where-Object { $_.data -ne '' })

        if (!$recs -or $recs.Count -eq 0) {
            # Build the new record set from scratch
            $bodyJson = "[{`"data`":`"$TxtValue`",`"ttl`":600}]"
        } else {
            # add the new record and build the body
            $recsNew = $recs + ([pscustomobject]@{data=$TxtValue;ttl=600})
            $bodyJson = ConvertTo-Json @($recsNew) -Compress
        }

        try {
            Write-Debug "Sending $bodyJson"
            Invoke-RestMethod "$apiRoot/$zone/records/TXT/$recShort" `
                -Method Put -Headers $headers -Body $bodyJson `
                -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to GoDaddy.

    .DESCRIPTION
        Add a DNS TXT record to GoDaddy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDKey
        The GoDaddy API Key.

    .PARAMETER GDSecret
        The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtGoDaddy '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dfasdasf3j42f' 'adsfj834sadfda'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtGoDaddy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDKey,
        [Parameter(Mandatory, Position = 3)]
        [string]$GDSecret,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://api.godaddy.com/v1/domains"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v1/domains"
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    $zone = Find-GDZone -RecordName $RecordName -GDKey $GDKey -GDSecret $GDSecret
    $recShort = ($RecordName -split ".$zone")[0]

    # Get a list of existing TXT records for this record name
    try {
        $recs = Invoke-RestMethod "$apiRoot/$zone/records/TXT/$recShort" `
            -Headers $headers @script:UseBasic -EA Stop
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # For some odd reason, the GoDaddy API doesn't have a method to delete a
        # particular record. The closest we can get is re-setting the set of records that
        # match a particular Type and Name. So we need to remove the record from our
        # set of results (which it may be the only one) and then send whatever's left.

        if ($recs.Count -le 1) {
            # It's the last one, but there doesn't seem to be a way to actually remove it,
            # so just clear the value from the record instead.
            $bodyJson = '[{"data":"","ttl":600}]'
        } else {
            # filter the record we want to delete and build the body
            $recsNew = $recs | Where-Object { $_.data -ne $TxtValue }
            $bodyJson = ConvertTo-Json @($recsNew) -Compress
        }

        try {
            Write-Debug "Sending $bodyJson"
            Invoke-RestMethod "$apiRoot/$zone/records/TXT/$recShort" `
                -Method Put -Headers $headers -Body $bodyJson `
                -ContentType 'application/json' @script:UseBasic -EA Stop | Out-Null
        } catch { throw }

    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from GoDaddy.

    .DESCRIPTION
        Remove a DNS TXT record from GoDaddy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDKey
        The GoDaddy API Key.

    .PARAMETER GDSecret
        The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtGoDaddy '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dfasdasf3j42f' 'adsfj834sadfda'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtGoDaddy {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

function Find-GDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$GDKey,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDSecret,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GDRecordZones) { $script:GDRecordZones = @{} }

    # check for the record in the cache
    if ($script:GDRecordZones.ContainsKey($RecordName)) {
        return $script:GDRecordZones.$RecordName
    }

    $apiRoot = "https://api.godaddy.com/v1/domains"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v1/domains"
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    # get the list of available zones
    try {
        $zones = (Invoke-RestMethod $apiRoot -Headers $headers @script:UseBasic -EA Stop) `
            | Where-Object {$_.status -eq "ACTIVE"} `
            | Select-Object -ExpandProperty domain
    } catch { throw }

    # We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i = 1; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones) {
            $zoneName = $zones | Where-Object { $_ -eq $zoneTest }
            $script:GDRecordZones.$RecordName = $zoneName
            return $zoneName
        }
    }

    return $null

    <#
    .SYNOPSIS
        Finds the appropriate DNS zone for the supplied record

    .DESCRIPTION
        Finds the appropriate DNS zone for the supplied record

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER GDKey
        The GoDaddy API Key.

    .PARAMETER GDSecret
        The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .EXAMPLE
        Find-GDZone -RecordName '_acme-challenge.site1.example.com' -GDKey 'asdfqwer12345678' -GDSecret 'dfasdasf3j42f'

        Finds the appropriate DNS zone for the supplied record
    #>
}
