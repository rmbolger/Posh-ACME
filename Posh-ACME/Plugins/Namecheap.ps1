function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
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
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$NCApiKeyInsecure,
        [switch]$NCUseSandbox,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $body = Get-NCCommonBody @PSBoundParameters } catch { throw }

    # get the current set of records for this domain
    try { $sld,$tld,$recs = Get-NCRecords $RecordName $body -UseSandbox:$NCUseSandbox } catch { throw }

    # strip quotes from the TXT value if they exist since namecheap strips them on the server side
    $TxtValue = $TxtValue.Trim('"')

    # get the short version of the record name to match against
    $zoneName = "$sld.$tld"
    $recMatch = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    if ($recMatch -eq '') { $recMatch = '@' }

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
            Invoke-NCAPI $addBody -Method Post -UseSandbox:$NCUseSandbox | Out-Null
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
        The API Key associated with your Namecheap account.

    .PARAMETER NCApiKeyInsecure
        (DEPRECATED) The API Key associated with your Namecheap account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "API Key" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'myusername' $key

        Adds a TXT record using a securestring object for NCApiKey. (Only works on Windows)
    #>
}

function Remove-DnsTxt {
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
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$NCApiKeyInsecure,
        [switch]$NCUseSandbox,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $body = Get-NCCommonBody @PSBoundParameters } catch { throw }

    # get the current set of records for this domain
    try { $sld,$tld,$recs = Get-NCRecords $RecordName $body -UseSandbox:$NCUseSandbox } catch { throw }

    # strip quotes from the TXT value if they exist since namecheap strips them on the server side
    $TxtValue = $TxtValue.Trim('"')

    # get the short version of the record name to match against
    $zoneName = "$sld.$tld"
    $recMatch = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    if ($recMatch -eq '') { $recMatch = '@' }

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
            Invoke-NCAPI $addBody -Method Post -UseSandbox:$NCUseSandbox | Out-Null
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
        The API Key associated with your Namecheap account.

    .PARAMETER NCApiKeyInsecure
        (DEPRECATED) The API Key associated with your Namecheap account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $key = Read-Host "API Key" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'myusername' $key

        Removes a TXT record using a securestring object for NCApiKey. (Only works on Windows)
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

# API Docs
# https://www.namecheap.com/support/api/intro.aspx

function Get-NCCommonBody {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$NCUsername,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=1)]
        [securestring]$NCApiKey,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=1)]
        [string]$NCApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # decrypt the secure password so we can add it to the querystring
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $NCApiKeyInsecure = [pscredential]::new('a',$NCApiKey).GetNetworkCredential().Password
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
        $ip = Invoke-RestMethod https://api.ipify.org -Verbose:$false -Debug:$false -EA Stop
        $body.ClientIp = $ip
        Write-Debug "Retrieved public IP as $ip"
    } catch { throw }

    return $body
}

function Get-NCRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CommonBody,
        [Parameter(Mandatory,Position=2)]
        [switch]$UseSandbox
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:NCRecordZones) { $script:NCRecordZones = @{} }

    # check for the record in the cache
    if ($script:NCRecordZones.ContainsKey($RecordName)) {
        $sld,$tld = $script:NCRecordZones.$RecordName
    }

    $CommonBody.Command = 'namecheap.domains.dns.getHosts'

    if (!$sld -or !$tld) {
        # try to find the zone from the record name by checking each possible SLD/TLD combo until we find a match
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {
            $sld = $pieces[$i]
            $tld = $pieces[($i+1)..($pieces.Count-1)] -join '.'
            Write-Debug "Checking $sld{dot}$tld"

            try {
                $response = Invoke-NCAPI ($CommonBody + @{SLD=$sld; TLD=$tld}) -UseSandbox:$UseSandbox

                Write-Debug "Found domain $sld{dot}$tld with $($response.ApiResponse.CommandResponse.DomainDNSGetHostsResult.host.Count) records"
                $recs = @($response.ApiResponse.CommandResponse.DomainDNSGetHostsResult.host)
                $script:NCRecordZones.$RecordName = $sld,$tld
                return $sld,$tld,$recs

            } catch {
                if ($_.Exception.Message -like 'Namecheap API Error 2019166*') {
                    Write-Debug "No match for $sld{dot}$tld. Continuing search."
                    continue
                }
                throw
            }
        }
        return
    } else {
        # use saved SLD/TLD from cache if we have it
        Write-Debug "Checking $sld{dot}$tld"
        try {
            $response = Invoke-NCAPI ($CommonBody + @{SLD=$sld; TLD=$tld}) -UseSandbox:$UseSandbox

            Write-Debug "Found domain $sld{dot}$tld with $($response.ApiResponse.CommandResponse.DomainDNSGetHostsResult.host.Count) records"
            $recs = @($response.ApiResponse.CommandResponse.DomainDNSGetHostsResult.host)
            $script:NCRecordZones.$RecordName = $sld,$tld
            return $sld,$tld,$recs
        } catch {
            throw
        }
    }
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
        [string]$Method='GET',
        [switch]$UseSandbox
    )

    # Namecheap's API seems to sporadically return error 3050750 with the message
    # "The agent is stopped or has been stopped, no additional provocateurs can be created."
    # My guess is that this is effectively an HTTP 503 "overloaded" error and if you retry
    # the query, it usually works. It was happening enough during testing that I felt like
    # adding some retry logic to the plugin. So this is a wrapper for Invoke-RestMethod
    # that will do that.

    $apiBase = 'https://api.namecheap.com/xml.response'
    if ($UseSandbox) { $apiBase = 'https://api.sandbox.namecheap.com/xml.response' }

    try {
        $queryParams = @{
            Uri = $apiBase
            Body = $body
            Method = $Method.ToUpper()
            Verbose = $false
            Debug = $false
            ErrorAction = 'Stop'
        } + $script:UseBasic

        # create a redacted version of the body for logging
        $redactedBody = $body.Clone()
        'ApiUser','ApiKey','UserName','ClientIp' | ForEach-Object {
            if ($redactedBody.ContainsKey($_)) {
                $redactedBody.Remove($_)
            }
        }

        for ($i=1; $i -le 5; $i++) {

            Write-Debug "$($Method.ToUpper()) $apiBase`nBODY (JSON for display purposes):$($redactedBody | ConvertTo-Json -Depth 5)"
            $response = Invoke-RestMethod @queryParams

            # return the response if no errors
            if ($response.ApiResponse.Status -eq 'OK') {
                # convert the xml object to a string for easier debugging if needed
                Write-Debug "Response:`n$($response.OuterXml)"
                return $response
            }

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
