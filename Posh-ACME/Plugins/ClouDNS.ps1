function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [ValidateSet('auth-id','sub-auth-id','sub-auth-user')]
        [string]$CDUserType,
        [Parameter(Mandatory,Position=3)]
        [string]$CDUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=4)]
        [securestring]$CDPassword,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=4)]
        [string]$CDPasswordInsecure,
        [switch]$CDPollPropagation,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if (-not $script:CDZonesToPoll) { $script:CDZonesToPoll = @() }

    # get our auth body parameters
    try { $body = Get-CDCommonBody @PSBoundParameters } catch { throw }

    # find the zone for this record
    try { $zoneName = Find-CDZone $RecordName $body } catch { throw }
    Write-Debug "Found zone $zoneName"

    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    # search for an existing record
    try { $rec = Get-CDTxtRecord $recShort $TxtValue $zoneName $body } catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $querystring = "/add-record.json?domain-name=$zoneName&host=$recShort&record=$TxtValue&record-type=TXT&ttl=60"
        Invoke-CDAPI $body $querystring -Method Post | Out-Null

        # add the zone to the polling list if necessary
        if ($CDPollPropagation -and $zoneName -notin $script:CDZonesToPoll) {
            Write-Debug "Adding $zoneName to polling list"
            $script:CDZonesToPoll += $zoneName
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to ClouDNS

    .DESCRIPTION
        Add a DNS TXT record to ClouDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CDUserType
        The type of user you're logging in as. This can be 'auth-id', 'sub-auth-id', or 'sub-auth-user'.

    .PARAMETER CDUsername
        The username or id for the account logging in.

    .PARAMETER CDPassword
        The password associated with your username. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER CDPasswordInsecure
        The password associated with your username. This standard String version can be used on any OS.

    .PARAMETER CDPollPropagation
        If specified, this will cause the Save method to block until each affected zone has updated its nameservers by querying the API for their status.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' 'auth-id' '12345' $pass

        Adds a TXT record using a securestring object for CDPassword.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' 'auth-id' '12345' 'xxxxxxxx'

        Adds a TXT record using a standard string object for CDPasswordInsecure.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [ValidateSet('auth-id','sub-auth-id','sub-auth-user')]
        [string]$CDUserType,
        [Parameter(Mandatory,Position=3)]
        [string]$CDUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=4)]
        [securestring]$CDPassword,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=4)]
        [string]$CDPasswordInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $body = Get-CDCommonBody @PSBoundParameters } catch { throw }

    # find the zone for this record
    try { $zoneName = Find-CDZone $RecordName $body } catch { throw }
    Write-Debug "Found zone $zoneName"

    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    # search for an existing record
    try { $rec = Get-CDTxtRecord $recShort $TxtValue $zoneName $body } catch { throw }

    if ($rec) {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        $querystring = "/delete-record.json?domain-name=$zoneName&record-id=$($rec.id)"
        Invoke-CDAPI $body $querystring -Method Post | Out-Null
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from ClouDNS

    .DESCRIPTION
        Remove a DNS TXT record from ClouDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CDUserType
        The type of user you're logging in as. This can be 'auth-id', 'sub-auth-id', or 'sub-auth-user'.

    .PARAMETER CDUsername
        The username or id for the account logging in.

    .PARAMETER CDPassword
        The password associated with your username. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER CDPasswordInsecure
        The password associated with your username. This standard String version can be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txtvalue' 'auth-id' '12345' $pass

        Removes a TXT record using a securestring object for CDPassword.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txtvalue' 'auth-id' '12345' 'xxxxxxxx'

        Removes a TXT record using a standard string object for CDPasswordInsecure.
    #>
}

function Save-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateSet('auth-id','sub-auth-id','sub-auth-user')]
        [string]$CDUserType,
        [Parameter(Mandatory,Position=1)]
        [string]$CDUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$CDPassword,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$CDPasswordInsecure,
        [switch]$CDPollPropagation,
        [int]$CDPollTimeout=300,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $pollZones = $script:CDZonesToPoll

    if ($CDPollPropagation -and $pollZones.Count -gt 0) {

        # get our auth body parameters
        try { $body = Get-CDCommonBody @PSBoundParameters } catch { throw }

        $startTime = [DateTimeOffset]::Now
        while ($pollZones.Count -gt 0 -and
            ([DateTimeOffset]::Now - $startTime).TotalSeconds -lt $CDPollTimeout) {

            Start-Sleep 10

            # reverse through the list so the index doesn't change
            # if we remove one
            for ($i = ($pollZones.Count-1); $i -ge 0; $i--) {

                $zone = $pollZones[$i]

                if (Test-CDIsUpdated $zone $body) {
                    Write-Verbose "$zone is updated"
                    $pollZones = @($pollZones | Where-Object { $_ -ne $zone })
                }
            }
        }
        Write-Debug "Polling stopped after $(([DateTimeOffset]::Now - $startTime).TotalSeconds) seconds"
    }

    $script:CDZonesToPoll = @()

    <#
    .SYNOPSIS
        Block while polling the API for zones to be updated at their nameservers.

    .DESCRIPTION
        When the CDPollPropagation switch is used, this function will use the is-updated ClouDNS API call wait until each zone has updated their associated nameservers.

    .PARAMETER CDUserType
        The type of user you're logging in as. This can be 'auth-id', 'sub-auth-id', or 'sub-auth-user'.

    .PARAMETER CDUsername
        The username or id for the account logging in.

    .PARAMETER CDPassword
        The password associated with your username. This SecureString version should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER CDPasswordInsecure
        The password associated with your username. This standard String version can be used on any OS.

    .PARAMETER CDPollPropagation
        If specified, this will cause the Save method to block until each affected zone has updated its nameservers by querying the API for their status.

    .PARAMETER CDPollTimeout
        The number of seconds to wait while polling before giving up. Defaults to 300 (5 minutes).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        PS C:\>Save-DnsTxt 'auth-id' '12345' $pass

        Saves TXT records using a securestring object for CDPassword.

    .EXAMPLE
        Save-DnsTxt 'auth-id' '12345' 'xxxxxxxx'

        Saves TXT records using a standard string object for CDPasswordInsecure.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://www.cloudns.net/wiki/article/42/

function Get-CDCommonBody {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateSet('auth-id','sub-auth-id','sub-auth-user')]
        [string]$CDUserType,
        [Parameter(Mandatory,Position=1)]
        [string]$CDUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$CDPassword,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$CDPasswordInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # decrypt the secure password so we can add it to the querystring
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $CDPasswordInsecure = (New-Object PSCredential "user",$CDPassword).GetNetworkCredential().Password
    }

    $body = @{
        $CDUserType = $CDUsername
        'auth-password' = $CDPasswordInsecure
    }

    return $body
}

function Find-CDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CommonBody
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:CDRecordZones) { $script:CDRecordZones = @{} }

    # check for the record in the cache
    if ($script:CDRecordZones.ContainsKey($RecordName)) {
        return $script:CDRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-CDAPI $CommonBody "/get-zone-info.json?&domain-name=$zoneTest"

            # check for results
            if ($response) {
                $script:CDRecordZones.$RecordName = $response.name
                return $response.name
            }
        } catch { Write-Debug ($_.Exception.Message) }
    }

    throw "No zone found for $RecordName"
}

function Get-CDTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordShortName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZoneName,
        [Parameter(Mandatory,Position=3)]
        [hashtable]$CommonBody
    )

    try {
        Write-Debug "Fetching TXT records for $RecordShortName in $ZoneName"
        $response = Invoke-CDAPI $CommonBody "/records.json?domain-name=$ZoneName&type=TXT&host=$RecordShortName"

        # ClouDNS made some weird choices here for how they return data vs an empty result.
        # The docs claim the response will be an array with records or presumably an empty
        # array if there are no results. However, an array is *only* returned when there are
        # no results. When there are results, it's returned as a dictionary of dictionaries
        # instead of an array of dictionaries. Here's an example.
        #
        # {
        #   "131173240": {"id":"131173240","type":"TXT","host":"test","record":"asdf"},
        #   "131173243": {"id":"131173243","type":"TXT","host":"test","record":"qwer"}
        # }

        if (-not $response -or $response -is [array]) { return $null }
        else {
            # pull out all of the inner results
            $recs = $response | Get-Member -MemberType NoteProperty | ForEach-Object { $response.($_.name) }

            # return only the record that matches the value we're looking for
            # which will return an empty set if not found
            Write-Debug "Checking for $TxtValue in the results"
            return ($recs | Where-Object { $_.record -eq $TxtValue })
        }
    } catch { throw }
}

function Test-CDIsUpdated {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ZoneName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CommonBody
    )

    Write-Verbose "Checking if $ZoneName nameservers are updated"
    $response = Invoke-CDAPI $CommonBody "/is-updated.json?domain-name=$ZoneName" -Verbose:$false

    return $response
}

function Invoke-CDAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$body,
        [Parameter(Position=1)]
        [string]$QueryAdditions,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get)
    )

    # ClouDNS's API is one that always returns HTTP 200 even on failure. So we're going to wrap it
    # and throw errors when we get a JSON error response.

    $apiBase = 'https://api.cloudns.net/dns'
    if ($QueryAdditions) { $apiBase += $QueryAdditions }

    $response = Invoke-RestMethod $apiBase -Body $body -Method $Method @script:UseBasic -EA Stop

    if ($response.status -and $response.status -eq 'failed') {
        throw "ClouDNS API Error: $($response.statusDescription)"
    }

    return $response
}
