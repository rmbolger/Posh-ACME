function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$YDAdminToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$YDAdminTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext token if the secure version was used
    # and make the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $YDAdminTokenInsecure = (New-Object PSCredential "user",$YDAdminToken).GetNetworkCredential().Password
    }
    $AuthHeader = @{ PddToken = $YDAdminTokenInsecure }

    try {
        Write-Verbose "Searching for existing TXT record"
        $zoneName,$rec = Get-YandexTxtRecord $RecordName $TxtValue $AuthHeader
    } catch { throw }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # add a new record
        $body = "domain=$zoneName&subdomain=$recShort&content=$TxtValue&type=TXT&ttl=1"
        try {
            Write-Verbose "Adding $RecordName with value $TxtValue"
            $response = Invoke-RestMethod 'https://pddimp.yandex.ru/api2/admin/dns/add' `
                -Method POST -Body $body -Headers $AuthHeader -ContentType 'application/x-www-form-urlencoded' `
                @script:UseBasic -EA Stop
        } catch { throw }
        if ($response.success -ne 'ok') {
            throw "Yandex API threw unexpected error: $($response.error)"
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Yandex.

    .DESCRIPTION
        Uses the Yandex DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER YDAdminToken
        The Yandex admin token generated for your account. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER YDAdminTokenInsecure
        The Yandex admin token generated for your account. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "Yandex Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'my-token'

        Adds the specified TXT record with the specified value using a plaintext token.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$YDAdminToken,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=2)]
        [string]$YDAdminTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext token if the secure version was used
    # and make the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $YDAdminTokenInsecure = (New-Object PSCredential "user",$YDAdminToken).GetNetworkCredential().Password
    }
    $AuthHeader = @{ PddToken = $YDAdminTokenInsecure }

    try {
        Write-Verbose "Searching for existing TXT record"
        $zoneName,$rec = Get-YandexTxtRecord $RecordName $TxtValue $AuthHeader
    } catch { throw }

    if ($rec) {
        # delete the record
        $body = "domain=$zoneName&record_id=$($rec.record_id)"
        try {
            Write-Verbose "Removing $RecordName with value $TxtValue"
            $response = Invoke-RestMethod 'https://pddimp.yandex.ru/api2/admin/dns/del' `
                -Method POST -Body $body -Headers $AuthHeader -ContentType 'application/x-www-form-urlencoded' `
                @script:UseBasic -EA Stop
        } catch { throw }
        if ($response.success -ne 'ok') {
            throw "Yandex API threw unexpected error: $($response.error)"
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Yandex.

    .DESCRIPTION
        Uses the Yandex DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER YDAdminToken
        The Yandex admin token generated for your account. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER YDAdminTokenInsecure
        The Yandex admin token generated for your account. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "Yandex Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Removes the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'my-token'

        Removes the specified TXT record with the specified value using a plaintext token.
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
# https://tech.yandex.com/domain/doc/concepts/api-dns-docpage/

function Get-YandexTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$AuthHeader
    )

    $apiRoot = 'https://pddimp.yandex.ru/api2/admin/dns'

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:YDRecordZones) { $script:YDRecordZones = @{} }

    # check for the record in the cache
    if ($script:YDRecordZones.ContainsKey($RecordName)) {
        $zone = $script:YDRecordZones.$RecordName
    }

    # Yandex doesn't really have a standalone API endpoint to check for the existence of a zone.
    # But you sort of get it for free with the endpoint to list a zone's records. If the zone
    # doesn't exist, you'll get an error saying as much.

    if ($zone) {
        # use the zone name we already found
        Write-Debug "Querying record list from zone $zone"
        try {
            $response = Invoke-RestMethod "$apiRoot/list?domain=$zone" -Headers $AuthHeader `
                @script:UseBasic -EA Stop
        } catch { throw }

        if ($response.success -ne 'ok') {
            if ($response.error -eq 'no_auth') {
                throw "Failed to authenticate against Yandex API. Double check token value."
            } else {
                throw "Yandex API threw unexpected error: $($response.error)"
            }
        }

    } else {
        # find the zone for the closest/deepest sub-zone that would contain the record.
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {

            $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
            Write-Debug "Checking $zoneTest"
            $response = $null

            try {
                $response = Invoke-RestMethod "$apiRoot/list?domain=$zoneTest" -Headers $AuthHeader `
                    @script:UseBasic -EA Stop
            } catch { throw }

            if ($response.success -eq 'ok') {
                $script:YDRecordZones.$RecordName = $zoneTest
                $zone = $zoneTest
                break
            } else {
                if ($response.error -eq 'no_auth') {
                    throw "Failed to authenticate against Yandex API. Double check token value."
                }
                elseif ($response.error -ne 'no_such_domain') {
                    throw "Yandex API threw unexpected error: $($response.error)"
                }
                $response = $null
            }
        }
    }

    if (-not $response) {
        throw "Unable to find Yandex hosted zone for $RecordName"
    }

    $rec = $response.records | Where-Object {
        $_.type -eq 'TXT' -and $_.fqdn -eq $RecordName -and $_.content -eq $TxtValue
    }

    return @($zone,$rec)
}
