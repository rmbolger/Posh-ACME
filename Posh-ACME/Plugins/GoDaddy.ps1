function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDKey,
        [Parameter(ParameterSetName='Secure', Mandatory, Position = 3)]
        [securestring]$GDSecretSecure,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 3)]
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

    # grab the plain text secret if necessary
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $GDSecret = [pscredential]::new('a',$GDSecretSecure).GetNetworkCredential().Password
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    if (-not ($zone = Find-GDZone $RecordName $headers $apiRoot)) {
        throw "Unable to find matching zone for $RecordName."
    }
    $recShort = ($RecordName -ireplace [regex]::Escape($zone), [string]::Empty).TrimEnd('.')
    if ($recShort -eq '') { $recShort = '@' }

    # Get a list of existing TXT records for this record name
    try {
        $queryParams = @{
            Uri = "$apiRoot/$zone/records/TXT/$recShort"
            Headers = $headers
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "GET $($queryParams.Uri)"
        $recs = Invoke-RestMethod @queryParams @script:UseBasic
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
            Write-Verbose "Adding a new TXT record for $recShort with value $TxtValue"
            $queryParams = @{
                Uri = "$apiRoot/$zone/records/TXT/$recShort"
                Method = 'Put'
                Body = $bodyJson
                Headers = $headers
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "PUT $($queryParams.Uri)`n$bodyJson"
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
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

    .PARAMETER GDSecretSecure
        The GoDaddy API Secret.

    .PARAMETER GDSecret
        (DEPRECATED) The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host 'API Secret' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key' $secret

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDKey,
        [Parameter(ParameterSetName='Secure', Mandatory, Position = 3)]
        [securestring]$GDSecretSecure,
        [Parameter(ParameterSetName='DeprecatedInsecure', Mandatory, Position = 3)]
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

    # grab the plain text secret if necessary
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $GDSecret = [pscredential]::new('a',$GDSecretSecure).GetNetworkCredential().Password
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    if (-not ($zone = Find-GDZone $RecordName $headers $apiRoot)) {
        throw "Unable to find matching zone for $RecordName."
    }
    $recShort = ($RecordName -ireplace [regex]::Escape($zone), [string]::Empty).TrimEnd('.')
    if ($recShort -eq '') { $recShort = '@' }

    # Get a list of existing TXT records for this record name
    try {
        $queryParams = @{
            Uri = "$apiRoot/$zone/records/TXT/$recShort"
            Headers = $headers
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "GET $($queryParams.Uri)"
        $recs = Invoke-RestMethod @queryParams @script:UseBasic
    } catch { throw }

    if (-not $recs -or $TxtValue -notin $recs.data) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    } else {
        # For some odd reason, the GoDaddy API doesn't have a method to delete a
        # particular record. The closest we can get is re-setting the set of records that
        # match a particular Type and Name. So we need to remove the record from our
        # set of results (which it may be the only one) and then send whatever's left.

        if ($recs.Count -le 1) {
            # It's the last one, but there's no way to remove it without re-writing the
            # entire contents of the zone. So just clear the value from the record instead.
            $bodyJson = '[{"data":"","ttl":600}]'
        } else {
            # filter the record we want to delete and build the body
            $recsNew = $recs | Where-Object { $_.data -ne $TxtValue }
            $bodyJson = ConvertTo-Json @($recsNew) -Compress
        }

        try {
            Write-Verbose "Removing a TXT record for $recShort with value $TxtValue"
            $queryParams = @{
                Uri = "$apiRoot/$zone/records/TXT/$recShort"
                Method = 'Put'
                Body = $bodyJson
                Headers = $headers
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "PUT $($queryParams.Uri)`n$bodyJson"
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
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

    .PARAMETER GDSecretSecure
        The GoDaddy API Secret.

    .PARAMETER GDSecret
        (DEPRECATED) The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host 'API Secret' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key' $secret

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
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

# API Docs:
# https://developer.godaddy.com/doc/endpoint/domains

function Find-GDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$AuthHeader,
        [Parameter(Mandatory, Position = 2)]
        [string]$ApiRoot
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GDRecordZones) { $script:GDRecordZones = @{} }

    # check for the record in the cache
    if ($script:GDRecordZones.ContainsKey($RecordName)) {
        return $script:GDRecordZones.$RecordName
    }

    # We need to find the closest/deepest sub-zone that would hold
    # the record rather than just adding it to the apex.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        # Even though GoDaddy doesn't officially support sub-zone DNS hosting, it's possible
        # to add a "domain" that is technically a sub-zone of an actual domain registered
        # elsewhere and just delegate to GoDaddy's nameservers. The web UI and API won't list
        # it as a domain in the normal domain list. But you can modify its records if you know
        # the zone name. We're going to search for the zone name by querying for its NS records.

        try {
            $queryParams = @{
                Uri = "$ApiRoot/$zoneTest/records/NS"
                Headers = $AuthHeader
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "GET $($queryParams.Uri)"
            # no error means we found the zone
            Invoke-RestMethod @queryParams @script:UseBasic | Out-Null
        } catch {
            # The NS check may throw either a 404 (Not Found) or a 422 (Unprocessable Entity) when
            # the zone is not found. Ignore those and re-throw anything else
            if ($_.Exception.Response.StatusCode -notin 404,422) {
                throw
            }
            continue
        }

        $script:GDRecordZones.$RecordName = $zoneTest
        return $zoneTest
    }

    return $null
}
