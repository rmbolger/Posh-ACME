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
    $AuthHeader = @{ Authorization = "Token $($DSTokenInsecure)" }

    try {
        $rrset, $recordUri, $domain, $subname = Find-DeSECRRset $RecordName $AuthHeader

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
            Invoke-deSEC $recordUri $AuthHeader -Method Patch -Body $data | Out-Null
        } else {
            $data = @{
                subname = $subname
                "type" = "TXT"
                records = @("`"$TxtValue`"")
                ttl = $DSTTL
            } | ConvertTo-Json

            Write-Verbose "Creating new RRset for record $RecordName with value $TxtValue."
            Invoke-deSEC "/domains/$($domain)/rrsets/" $AuthHeader -Method Post -Body $data | Out-Null
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
        $DSToken = ConvertTo-SecureString 'token-value' -AsPlainText -Force
        Add-DnsTxtDeSec '_acme-challenge.example.com' 'txt-value' $DSToken

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
    $AuthHeader = @{ Authorization = "Token $($DSTokenInsecure)" }

    # get existing record
    try {
        $rrset, $recordUri, $domain, $subname = Find-DeSECRRset $RecordName $AuthHeader
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
        $data = @{
            records = $rrset.records.where( { $_ -ne "`"$TxtValue`"" } )
        } | ConvertTo-Json
        Write-Verbose "Deleting record $RecordName with value $TxtValue."
        Invoke-deSEC $recordUri $AuthHeader -Method Patch -Body $data | Out-Null
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
        $DSToken = ConvertTo-SecureString 'token-value' -AsPlainText -Force
        Remove-DnsTxtDeSec '_acme-challenge.example.com' 'txt-value' $DSToken

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

# API Docs:
# https://desec.readthedocs.io/en/latest/quickstart.html

function Find-DeSECRRset {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$AuthHeader
    )

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($domain = Find-DeSECZone $RecordName $AuthHeader)) {
        throw "Unable to find deSEC hosted zone for $RecordName"
    }

    $subname = ($RecordName -ireplace [regex]::Escape($domain), [string]::Empty).TrimEnd('.')

    # .NET thinks all URLS are Windows filenames (no trailing dot)
    # replace trailing ... with escaped %2e%2e%2e
    # https://stackoverflow.com/questions/856885/httpwebrequest-to-url-with-dot-at-the-end
    $recordUri = "/domains/$($domain)/rrsets/$($subname)%2e%2e%2e/TXT/"
    Write-Debug "$RecordName has URI: $recordUri"

    # get existing record
    try {
        $rrset = Invoke-deSEC $recordUri $AuthHeader
        return $rrset, $recordUri, $domain, $subname
    } catch {
        if (404 -eq $_.Exception.Response.StatusCode) {
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
        [hashtable]$AuthHeader
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
        $zones = (Invoke-deSEC "/domains/" $AuthHeader).name
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
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones) {
            $script:DSRecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }

    return $null
}

function Invoke-DeSEC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Query,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$AuthHeader,
        [Parameter(Position=2)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [string]$Body
    )

    # To gracefully deal with deSEC's API throttling, we need to catch HTTP 429
    # responses which *should* have a Retry-After header indicating how long we
    # need to wait to retry the request.

    # build the appropriate function parameters to splat
    $queryParams = @{
        Uri = "https://desec.io/api/v1$Query"
        Method = $Method
        Headers = $AuthHeader
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $queryParams.ContentType = 'application/json'
        $queryParams.Body = $Body
    }

    $retryHeader = 'Retry-After'
    $retrySeconds = 30  # default in case the header is missing from the response
    do {
        $retry = $false
        try { Invoke-RestMethod @queryParams @script:UseBasic }
        catch {
            # re-throw anything other than HTTP 429
            if (429 -ne $_.Exception.Response.StatusCode) {
                throw
            }
            $retry = $true

            # Since we can't catch explicit exception types between PowerShell editions
            # without errors for non-existent types, we need to string match the type names
            # and re-throw anything we don't care about.
            $exType = $_.Exception.GetType().FullName
            $response = $_.Exception.Response

            if ('System.Net.WebException' -eq $exType) {
                # PowerShell Desktop edition
                # Response object: System.Net.HttpWebResponse

                # grab the retry timeout suggestion if it exists
                if ($retryHeader -in $response.Headers) {
                    $retrySeconds = $response.GetResponseHeader($retryHeader) | Select-Object -First 1
                    Write-Debug "Got $retrySeconds from $retryHeader header"
                }

            } elseif ('Microsoft.PowerShell.Commands.HttpResponseException' -eq $exType) {
                # PowerShell Core edition
                # Linux Response: System.Net.Http.CurlHandler+CurlResponseMessage
                #   Mac Response: ???
                #   Win Response: System.Net.Http.HttpResponseMessage

                # grab the retry timeout suggestion if it exists
                if ($retryHeader -in $response.Headers.Key) {
                    $retrySeconds = ($response.Headers | Where-Object { $_.Key -eq $retryHeader }).Value | Select-Object -First 1
                    Write-Debug "Got $retrySeconds from $retryHeader header"
                }

            } else { throw }

            # Sleep for the suggested time
            Write-Verbose "deSEC API throttling triggered. Will retry in $retrySeconds second(s)."
            Start-Sleep -Seconds $retrySeconds
        }
    } while ($retry)

}
