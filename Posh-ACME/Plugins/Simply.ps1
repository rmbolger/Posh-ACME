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
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$SimplyAPIKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SimplyAPIKeyInsecure = [pscredential]::new('a',$SimplyAPIKey).GetNetworkCredential().Password
    }

    $apiRoot = "https://api.simply.com/1/$SimplyAccount/$SimplyAPIKeyInsecure/my/products"

    $zone,$rec = Get-SimplyTXTRecord $RecordName $TxtValue $apiRoot

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
        Write-Debug "New Record body: `n$body"

        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        try {
            $postParams = @{
                Uri = "$apiRoot/$zone/dns/records"
                Method = 'POST'
                Body = $body
                ContentType = 'application/json'
                ErrorAction = 'Stop'
            }
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
        The API Key associated with the account as a SecureString value. This should only be used on Windows or any OS with PowerShell 6.2+.
    .PARAMETER SimplyAPIKeyInsecure
        The API Key associated with the account as a standard string value.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'S123456' 'key-value'

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
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$SimplyAPIKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SimplyAPIKeyInsecure = [pscredential]::new('a',$SimplyAPIKey).GetNetworkCredential().Password
    }

    $apiRoot = "https://api.simply.com/1/$SimplyAccount/$SimplyAPIKeyInsecure/my/products"

    $zone,$rec = Get-SimplyTXTRecord $RecordName $TxtValue $apiRoot

    if ($rec) {

        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        try {
            $delParams = @{
                Uri = "$apiRoot/$zone/dns/records/$($rec.record_id)"
                Method = 'DELETE'
                ErrorAction = 'Stop'
            }
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
        The API Key associated with the account as a SecureString value. This should only be used on Windows or any OS with PowerShell 6.2+.
    .PARAMETER SimplyAPIKeyInsecure
        The API Key associated with the account as a standard string value.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'S123456' 'key-value'

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
    $zone = $script:SimplyRecordZones.$RecordName

    if (-not $zone) {
        # find the zone for the closest/deepest sub-zone that would contain the record.
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {
            $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
            Write-Debug "Checking $zoneTest"

            try {
                $response = Invoke-RestMethod "$apiRoot/$zoneTest/dns" -EA Stop @script:UseBasic
            }
            catch {
                # We're expecting 404 errors here for zones that aren't actually the main domain.
                # So ignore them and throw anything else.
                if (404 -ne $_.Exception.Response.StatusCode.value__) {
                    Write-Debug "$_"
                    throw
                }
                continue
            }

            if ($response.status -eq 200) {
                $script:SimplyRecordZones.$RecordName = $zoneTest
                $zone = $zoneTest
            } else {
                Write-Debug "Simply Response: `n$($response | ConvertTo-Json)"
                throw "Unexpected response from Simply: $($response.message)."
            }
        }
    }

    if ($RecordName -eq $zone) {
        $recShort = '@'
    } else {
        $recShort = ($RecordName -ireplace [regex]::Escape($zone), [string]::Empty).TrimEnd('.')
    }

    # query the zone records and check for the one we care about
    try {
        $response = Invoke-RestMethod "$apiRoot/$zone/dns/records" -EA Stop @script:UseBasic
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
        return $zone,$rec

    } else {
        Write-Debug "Simply Response: `n$($response | ConvertTo-Json)"
        throw "Unexpected response from Simply: $($response.message)."
    }

}
