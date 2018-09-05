function Add-DnsTxtDeSec {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DSToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$DSTokenInsecure,
        [Parameter()]
        [int]$DSTTL = 300,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure token to a normal string
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DSTokenInsecure = (New-Object PSCredential ("user", $DSToken)).GetNetworkCredential().Password
    }

    try {
        $rrset, $recordUri, $domain, $subname = Find-DeSECRRset $RecordName $DSTokenInsecure

        $auth = Get-DeSECAuthHeader $DSTokenInsecure
        if ($rrset) {
            if ("`"$TxtValue`"" -in $rrset.records) {
                Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
                return
            }

            $rrset.records += "`"$TxtValue`""
            $data = @{
                records = $rrset.records
            } | ConvertTo-Json
            Write-Verbose "Adding record $RecordName with value $TxtValue to existing RRset."
            Invoke-RestMethod $recordUri -Method Patch -Headers $auth -Body $data `
                -ContentType 'application/json' @script:UseBasic | Out-Null
        } else {
            $data = @{
                subname = $subname
                "type" = "TXT"
                records = @("`"$TxtValue`"")
                ttl = $DSTTL
            } | ConvertTo-Json

            Write-Verbose "Creating new RRset for record $RecordName with value $TxtValue."
            Invoke-RestMethod "https://desec.io/api/v1/domains/$($domain)/rrsets/" -Method Post -Body $data `
                -Headers $auth -ContentType 'application/json' @script:UseBasic | Out-Null
        }
    } catch {
        throw
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to deSEC.

    .DESCRIPTION
        Add a DNS TXT record to deSEC.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DSToken
        The deSEC API authentication token for your account.

    .PARAMETER DSTokenInsecure
        The deSEC API authentication token for your account.

    .PARAMETER DSTTL
        The TTL of new TXT record (default 300).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $DSToken = ConvertTo-SecureString 'yourdesectoken' -AsPlainText -Force
        Add-DnsTxtDeSec '_acme-challenge.site1.example.com' 'asdfqwer12345678' $DSToken

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtDeSec {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$DSToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$DSTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the secure token to a normal string
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DSTokenInsecure = (New-Object PSCredential ("user", $DSToken)).GetNetworkCredential().Password
    }

    # get existing record
    try {
        $rrset, $recordUri, $domain, $subname = Find-DeSECRRset $RecordName $DSTokenInsecure
        if (!$rrset) {
            Write-Debug "Record $RecordName doesn't exist. Nothing to do."
            return
        }
    } catch {
        throw
    }

    if ("`"$TxtValue`"" -notin $rrset.records) {
        Write-Debug "Record $RecordName doesn't contain $TxtValue. Nothing to do."
        return
    }

    try {
        $auth = Get-DeSECAuthHeader $DSTokenInsecure

        $data = @{
            records = $rrset.records.where( { $_ -ne "`"$TxtValue`"" } )
        } | ConvertTo-Json
        Write-Verbose "Deleting record $RecordName with value $TxtValue."
        Invoke-RestMethod $recordUri -Method Patch -Headers $auth -Body $data `
            -ContentType 'application/json' @script:UseBasic | Out-Null
    } catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from deSEC.

    .DESCRIPTION
        Remove a DNS TXT record from deSEC.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DSToken
        The deSEC API authentication token for your account.

    .PARAMETER DSTokenInsecure
        The deSEC API authentication token for your account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $DSToken = ConvertTo-SecureString 'yourdesectoken' -AsPlainText -Force
        Remove-DnsTxtDeSec '_acme-challenge.site1.example.com' 'asdfqwer12345678' $DSToken

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtDeSec {
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

function Find-DeSECRRset {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$DSTokenInsecure
    )

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($domain = Find-DeSECZone $RecordName $DSTokenInsecure)) {
        throw "Unable to find deSEC hosted zone for $RecordName"
    }

    $subname = $RecordName.Replace(".$domain",'')

    # .NET thinks all URLS are Windows filenames (no trailing dot)
    # replace trailing ... with escaped %2e%2e%2e
    # https://stackoverflow.com/questions/856885/httpwebrequest-to-url-with-dot-at-the-end
    $recordUri = "https://desec.io/api/v1/domains/$($domain)/rrsets/$($subname)%2e%2e%2e/TXT/"
    Write-Debug "$RecordName has URI: $recordUri"

    $auth = Get-DeSECAuthHeader $DSTokenInsecure

    # get existing record
    try {
        $rrset = Invoke-RestMethod $recordUri -Headers $auth `
            -ContentType 'application/json' @script:UseBasic
        return $rrset, $recordUri, $domain, $subname
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 404) {
            return $null, $null, $domain, $subname
        }
        throw
    }
}

function Find-DeSECZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$DSTokenInsecure
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DSRecordZones) { $script:DSRecordZones = @{} }

    # check for the record in the cache
    if ($script:DSRecordZones.ContainsKey($RecordName)) {
        return $script:DSRecordZones.$RecordName
    }

    # get the list of available zones
    try {
        $auth = Get-DeSECAuthHeader $DSTokenInsecure
        $zones = (Invoke-RestMethod "https://desec.io/api/v1/domains/" -Headers $auth @script:UseBasic).name
    } catch { throw }

    # Since the provider could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones) {
            $script:DSRecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }

    return $null
}

function Get-DeSECAuthHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DSTokenInsecure
    )

    # now build the header hashtable
    $header = @{
       Authorization = "Token $($DSTokenInsecure)"
    }

    return $header
}
