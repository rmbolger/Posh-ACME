function Add-DnsTxtClouDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
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

    $recShort = $RecordName.Replace(".$zoneName",'')

    # search for an existing record
    try { $rec = Get-CDTxtRecord $recShort $TxtValue $zoneName $body } catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $querystring = "/add-record.json?domain-name=$zoneName&host=$recShort&record=$TxtValue&record-type=TXT&ttl=60"
        Invoke-CDAPI $body $querystring -Method Post | Out-Null
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
        The password associated with your username. This SecureString version should only be used on Windows.

    .PARAMETER CDPasswordInsecure
        The password associated with your username. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        PS C:\>Add-DnsTxtClouDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'auth-id' '12345' $pass

        Adds a TXT record using a securestring object for CDPassword. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxtClouDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'auth-id' '12345' 'xxxxxxxx'

        Adds a TXT record using a standard string object for CDPasswordInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxtClouDNS {
    [CmdletBinding()]
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

    $recShort = $RecordName.Replace(".$zoneName",'')

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
        The password associated with your username. This SecureString version should only be used on Windows.

    .PARAMETER CDPasswordInsecure
        The password associated with your username. This standard String version should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        PS C:\>Remove-DnsTxtClouDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'auth-id' '12345' $pass

        Removes a TXT record using a securestring object for CDPassword. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxtClouDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'auth-id' '12345' 'xxxxxxxx'

        Removes a TXT record using a standard string object for CDPasswordInsecure. (Use this on non-Windows)
    #>
}

function Save-DnsTxtClouDNS {
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

# API Docs
# https://www.cloudns.net/wiki/article/42/

function Get-CDCommonBody {
    [CmdletBinding(DefaultParameterSetName='Secure')]
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

    $querystring = "/list-zones.json?page=1&rows-per-page=10"

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-CDAPI $CommonBody "$querystring&search=$zoneTest"

            # check for results
            if ($response) {
                $script:CDRecordZones.$RecordName = $response[0].name
                return $response[0].name
            }
        } catch { throw }
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
