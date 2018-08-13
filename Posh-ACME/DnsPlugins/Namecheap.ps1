function Add-DnsTxtNamecheap {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NCUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$NCApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$NCApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $body = Get-NCCommonBody @PSBoundParameters } catch { throw }

    # get the SLD/TLD for this record
    try { $sld,$tld = Find-NCDomain $RecordName $body } catch { throw }
    Write-Debug "Found domain $sld{dot}$tld"

    # get the current set of records for this domain
    try { $recs = Get-NCRecords $sld $tld $body } catch { throw }

    # get the short version of the record name to match against
    $recMatch = $RecordName.Replace(".$sld.$tld",'')

    # check for an existing record
    if ($recs | Where-Object { $_.Name -eq $recMatch -and $_.Type -eq 'TXT' -and $_.Address -eq $TxtValue }) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."

    } else {

        # initialize the body with the record we want to add
        $addBody = @{
            SLD = $sld
            TLD = $tld
            HostName1 = $recMatch
            RecordType1 = 'TXT'
            Address1 = $TxtValue
            TTL1 = 60
        }

        # now add the rest of the existing records
        Add-NCRecordParams $recs $addBody 2

        # now add a copy of the auth params, domain, and update the Command
        $body.Keys | ForEach-Object { $addBody.$_ = $body.$_ }
        $addBody.Command = 'namecheap.domains.dns.setHosts'

        # send it all over
        try {
            Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
            Invoke-NCAPI $addBody -Method Post | Out-Null
        } catch { throw }

    }




    <#
    .SYNOPSIS
        Add a DNS TXT record to Namecheap

    .DESCRIPTION
        Add a DNS TXT record to Namecheap

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NCUsername
        The username of your Namecheap account.

    .PARAMETER NCApiKey
        The API Key associated with your Namecheap account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER NCApiKeyInsecure
        The API Key associated with your Namecheap account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "API Key" -AsSecureString
        PS C:\>Add-DnsTxtNamecheap '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' $key

        Adds a TXT record using a securestring object for NCApiKey. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxtNamecheap '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' 'xxxxxxxx'

        Adds a TXT record using a standard string object for NCApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Remove-DnsTxtNamecheap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$NCUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$NCApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$NCApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $body = Get-NCCommonBody @PSBoundParameters } catch { throw }

    # get the SLD/TLD for this record
    try { $sld,$tld = Find-NCDomain $RecordName $body } catch { throw }
    Write-Debug "Found domain $sld{dot}$tld"

    # get the current set of records for this domain
    try { $recs = Get-NCRecords $sld $tld $body } catch { throw }

    # get the short version of the record name to match against
    $recMatch = $RecordName.Replace(".$sld.$tld",'')

    # check for an existing record
    if ($delRec = $recs | Where-Object { $_.Name -eq $recMatch -and $_.Type -eq 'TXT' -and $_.Address -eq $TxtValue }) {

        # initialize the body for the removal
        $addBody = @{
            SLD = $sld
            TLD = $tld
        }

        # now add a copy of the auth params, domain, and update the Command
        $body.Keys | ForEach-Object { $addBody.$_ = $body.$_ }
        $addBody.Command = 'namecheap.domains.dns.setHosts'

        # now add the rest of the existing records *except* the one we're removing
        Add-NCRecordParams ($recs | Where-Object { $_.HostId -ne $delRec.HostId }) $addBody 1

        # send it all over
        try {
            Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
            Invoke-NCAPI $addBody -Method Post | Out-Null
        } catch { throw }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }




    <#
    .SYNOPSIS
        Remove a DNS TXT record from Namecheap

    .DESCRIPTION
        Remove a DNS TXT record from Namecheap

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER NCUsername
        The username of your Namecheap account.

    .PARAMETER NCApiKey
        The API Key associated with your Namecheap account. This SecureString version of the API Key should only be used on Windows.

    .PARAMETER NCApiKeyInsecure
        The API Key associated with your Namecheap account. This standard String version of the API Key should be used on non-Windows OSes.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "API Key" -AsSecureString
        PS C:\>Remove-DnsTxtNamecheap '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' $key

        Removes a TXT record using a securestring object for NCApiKey. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxtNamecheap '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'myusername' 'xxxxxxxx'

        Removes a TXT record using a standard string object for NCApiKeyInsecure. (Use this on non-Windows)
    #>
}

function Save-DnsTxtNamecheap {
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
# https://www.namecheap.com/support/api/intro.aspx

function Get-NCCommonBody {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$NCUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=1)]
        [securestring]$NCApiKey,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=1)]
        [string]$NCApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # decrypt the secure password so we can add it to the querystring
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $NCApiKeyInsecure = (New-Object PSCredential "user",$NCApiKey).GetNetworkCredential().Password
    }

    $body = @{
        ApiUser = $NCUsername
        ApiKey = $NCApiKeyInsecure
        Command = ''
        UserName = $NCUsername
        ClientIp = ''
    }

    # The Namecheap API requires you to whitelist the IPs you are connecting from and they
    # claim you must send that IP as a parameter called ClientIp in every request as well.
    # In testing, it seems like they don't check the value for ClientIp at all and only check
    # the actual IP you're coming from. But we'll try to play by the rules anyway.
    try {
        $ip = Invoke-RestMethod https://api.ipify.org -EA Stop
        $body.ClientIp = $ip
        Write-Debug "Retrieved public IP as $ip"
    } catch { throw }

    return $body
}

function Find-NCDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CommonBody
    )

    $CommonBody.Command = 'namecheap.domains.getList'

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:NCRecordZones) { $script:NCRecordZones = @{} }

    # check for the record in the cache
    if ($script:NCRecordZones.ContainsKey($RecordName)) {
        return $script:NCRecordZones.$RecordName
    }

    # Namecheap doesn't appear to support hosting sub-zones explicitly, but we also can't assume
    # the registered domain is only two pieces (example.com). There are plenty of valid third level
    # domains like (example.co.uk). So we're going to search for the zone from longest to shortest
    # set of pieces.
    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-NCAPI $CommonBody -QueryAdditions "SearchTerm=$zoneTest"

            # check for results
            if ($response.ApiResponse.CommandResponse.Paging.TotalItems -gt 0) {
                # we found the domain, but subsequent queries in the namecheap API
                # require us to distinguish between "SLD" and "TLD" and it's unclear
                # from their docs what to do with third level domains like example.co.uk.
                # So for now, we're going to assume the SLD is the first piece (example)
                # and the TLD is everything after (co.uk).
                $sld = $zoneTest.Substring(0,$zoneTest.IndexOf('.'))
                $tld = $zoneTest.Substring($zoneTest.IndexOf('.')+1)

                $script:NCRecordZones.$RecordName = $sld,$tld
                return $sld,$tld
            }
        } catch { throw }
    }

    return $null
}

function Get-NCRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$SLD,
        [Parameter(Mandatory,Position=1)]
        [string]$TLD,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$CommonBody
    )

    try {
        Write-Debug "Fetching records for $SLD{dot}$TLD"
        $CommonBody.Command = 'namecheap.domains.dns.getHosts'
        $response = Invoke-NCAPI $CommonBody -QueryAdditions "SLD=$SLD&TLD=$TLD"

        $recs = @($response.ApiResponse.CommandResponse.DomainDNSGetHostsResult.host)
        Write-Debug "Found $($recs.Count) records"

        return $recs

    } catch { throw }
}

function Add-NCRecordParams {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [Xml.XmlElement[]]$recs,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$body,
        [Parameter(Mandatory,Position=2)]
        [int]$StartIndex
    )

    # So Namecheap's API is kind of wacky and in order to do a record update, you basically need
    # to send the entire record list back for the domain in question as it will overwrite all
    # existing records. And if that wasn't bad enough, we can't just send the XML body back as-is.
    # We have to re-format the whole thing into querystring-like arguments with index numbers for
    # each set of record details (HostName1, RecordType1, HostName2, RecordType2, etc). So this
    # function will do just that.

    for ($i=0; $i -lt $recs.Count; $i++) {
        $recIndex = $i + $StartIndex
        $body."HostName$recIndex"   = $recs[$i].Name
        $body."RecordType$recIndex" = $recs[$i].Type
        $body."Address$recIndex"    = $recs[$i].Address
        $body."TTL$recIndex"        = $recs[$i].TTL
        $body."MXPref$recIndex"     = $recs[$i].MXPref
    }

}

function Invoke-NCAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$body,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [string]$QueryAdditions
    )

    # Namecheap's API seems to sporadically return error 3050750 with the message
    # "The agent is stopped or has been stopped, no additional provocateurs can be created."
    # My guess is that this is effectively an HTTP 503 "overloaded" error and if you retry
    # the query, it usually works. It was happening enough during testing that I felt like
    # adding some retry logic to the plugin. So this is a wrapper for Invoke-RestMethod
    # that will do that.

    $apiBase = 'https://api.namecheap.com/xml.response'
    if ($QueryAdditions) { $apiBase += "?$QueryAdditions" }

    try {

        for ($i=1; $i -le 5; $i++) {

            $response = Invoke-RestMethod $apiBase -Body $body -Method $Method @script:UseBasic -EA Stop

            # return the response if no errors
            if ($response.ApiResponse.Status -eq 'OK') { return $response }

            # loop/retry on the 3050750 error
            if (3050750 -eq $response.ApiResponse.Errors.Error.Number) {
                Write-Verbose "Namecheap server busy. Retrying..."
                Start-Sleep -Seconds 2
                continue
            }

            # throw any other error
            throw "Namecheap API Error $($response.ApiResponse.Errors.Error.Number): $($response.ApiResponse.Errors.Error.'#text')"

        }

    } catch { throw }

}
