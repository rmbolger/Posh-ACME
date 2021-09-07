function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$SimplyAccount,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$SimplyAPIKey,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$SimplyAPIKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SimplyAPIKeyInsecure = [pscredential]::new('a',$SimplyAPIKey).GetNetworkCredential().Password
    }
    $apiRoot = "https://api.simply.com/1/$SimplyAccount/$SimplyAPIKeyInsecure/my/products"

    $zoneID,$rec = Get-SimplyTXTRecord $RecordName $TxtValue $apiRoot

    if ($rec) {
        Write-Verbose "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {

        # build the new record object
        $body = @{
            name = $RecordName # Simply allows FQDNs here even though they return short names
            type = 'TXT'
            data = $TxtValue
            ttl = 60
        } | ConvertTo-Json

        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        try {
            $postParams = @{
                Uri = "$apiRoot/$zoneID/dns/records"
                Method = 'POST'
                Body = $body
                ContentType = 'application/json'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "POST $(SimplyRedactKey $postParams.Uri)`n$body"
            Invoke-RestMethod @postParams @script:UseBasic | Out-Null
        }
        catch {
            Write-Debug $_
            throw
        }

    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Simply.
    .DESCRIPTION
        Use Simply api to add a TXT record to a Simply DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER SimplyAccount
        The account name of the account used to connect to Simply API (e.g. S123456)
    .PARAMETER SimplyAPIKey
        The API Key associated with the account as a SecureString value.
    .PARAMETER SimplyAPIKeyInsecure
        (DEPRECATED) The API Key associated with the account as a standard string value.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'S123456' $key

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$SimplyAccount,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$SimplyAPIKey,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$SimplyAPIKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SimplyAPIKeyInsecure = [pscredential]::new('a',$SimplyAPIKey).GetNetworkCredential().Password
    }
    $apiRoot = "https://api.simply.com/1/$SimplyAccount/$SimplyAPIKeyInsecure/my/products"

    $zoneID,$rec = Get-SimplyTXTRecord $RecordName $TxtValue $apiRoot

    if ($rec) {

        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        try {
            $delParams = @{
                Uri = "$apiRoot/$zoneID/dns/records/$($rec.record_id)"
                Method = 'DELETE'
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "DELETE $(SimplyRedactKey $delParams.Uri)"
            Invoke-RestMethod @delParams @script:UseBasic | Out-Null
        }
        catch {
            Write-Debug $_
            throw
        }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Removes a DNS TXT record from Simply.
    .DESCRIPTION
        Use Simply API to remove a TXT record from a Simply DNS zone.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER SimplyAccount
        The account name of the account used to connect to Simply API (e.g. S123456)
    .PARAMETER SimplyAPIKey
        The API Key associated with the account as a SecureString value.
    .PARAMETER SimplyAPIKeyInsecure
        (DEPRECATED) The API Key associated with the account as a standard string value.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $key = Read-Host 'API Key' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'S123456' $key

        Removes a TXT record from the specified site with the specified value.
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
# https://www.simply.com/en/docs/api/

function Get-SimplyTXTRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ApiRoot
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:SimplyRecordZones) { $script:SimplyRecordZones = @{} }

    # check for the record in the cache
    #$zone,$zoneID = $script:SimplyRecordZones.$RecordName
    $zoneID,$recShort = $script:SimplyRecordZones.$RecordName

    if (-not $zoneID) {

        # query all of the domains on the account
        try {
            $getParams = @{
                Uri = $ApiRoot
                ErrorAction = 'Stop'
                Verbose = $false
            }
            Write-Debug "GET $(SimplyRedactKey $getParams.Uri)"
            $products = (Invoke-RestMethod @getParams @script:UseBasic).products
        } catch { throw }

        # find the zone for the closest/deepest sub-zone that would contain the record.
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {
            $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
            Write-Debug "Checking $zoneTest"

            $match = $products | Where-Object { $zoneTest -eq $_.domain.name_idn }
            if ($match) {
                # To query the records, we need the "object" id of the zone which is currently
                # the non-punycode version of the domain name. But that's not guaranteed to always
                # be the case. So just treat it like an arbitrary ID value.
                $zoneID = $match.object

                # derive the short record name
                if ($RecordName -eq $match.domain.name_idn) {
                    $recShort = '@'
                } else {
                    $recShort = ($RecordName -ireplace [regex]::Escape($match.domain.name_idn), [string]::Empty).TrimEnd('.')
                }

                $script:SimplyRecordZones.$RecordName = $zoneID,$recShort
                break
            }
        }
    }

    # query the zone records and check for the one we care about
    try {
        $getParams = @{
            Uri = "$ApiRoot/$zoneID/dns/records"
            ErrorAction = 'Stop'
            Verbose = $false
        }
        Write-Debug "GET $(SimplyRedactKey $getParams.Uri)"
        $response = Invoke-RestMethod @getParams @script:UseBasic
    }
    catch {
        Write-Debug "$_"
        throw
    }

    if ($response.status -eq 200) {

        $rec = $response.records | Where-Object {
            $_.type -eq 'TXT' -and
            $_.name -eq $recShort -and
            $_.data -eq $TxtValue
        }

        # return the zone name and the record
        return $zoneID,$rec

    } else {
        Write-Debug "Simply Response: `n$($response | ConvertTo-Json)"
        throw "Unexpected response from Simply: $($response.message)."
    }

}

function SimplyRedactKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Uri
    )

    # Simply's API auth puts the API secret right in the URL which makes logging what we're
    # doing unintentionally expose that secret in the logs. We're going to try and redact
    # the value before we log it.
    # https://api.simply.com/1/S012345/ABCDEFGHIJKLMNOP/my/products"
    #                                  [  5th index   ]
    $pieces = $Uri.Split('/')
    $pieces[5] = 'XXXXXXXX'
    return ($pieces -join '/')
}
