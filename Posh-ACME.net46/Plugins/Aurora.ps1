function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [String]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [String]$TxtValue,

        [Parameter(Mandatory, Position = 2)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$AuroraCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$AuroraApi = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    Write-Debug "convert the Credential to normal String values"
    $auroraAuthorization = @{ Api = $AuroraApi; Key = $AuroraCredential.UserName; Secret = $AuroraCredential.GetNetworkCredential().Password }

    Write-Debug "Attempting to find hosted zone for $RecordName"
    try {
        $zone = Invoke-AuroraFindZone -RecordName $RecordName @auroraAuthorization
        $ZoneID = $zone.id
        $zoneName = $zone.name
    } catch { throw }

    if ((-not $ZoneID) -or (-not $zoneName)) {
        throw "Unable to find Aurora hosted zone for $RecordName"
    }

    Write-Debug "Separate the portion of the name that doesn't contain the zone name"
    $recordPath = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    Write-Debug "[recordPath:$recordPath][RecordName:$RecordName]"

    Write-Debug "Query the existing record(s)"
    try {
        $records = @()
        $records += Invoke-AuroraGetRecord -RecordName $recordPath -ZoneID $ZoneID @auroraAuthorization
    } catch { throw }

    Write-Debug "Check if our value is already in there"
    if ($TxtValue -in $records.content) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    } else {
        Write-Debug "Record $RecordName does not contain $TxtValue. Adding it."
        try {
            $recAdded = Invoke-AuroraAddRecord -ZoneID $ZoneID -Name $recordPath -Content $TxtValue -Type 'TXT' -TTL 300 @auroraAuthorization
        } catch { throw }
    }
    <#
    .SYNOPSIS
        Add a DNS TXT record to Aurora DNS.
    .DESCRIPTION
        Add a DNS TXT record to Aurora DNS.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER Credential
        The Key and Secret in a PSCredential (secure) parameter
    .PARAMETER Key
        The Aurora DNS API key for your account.
    .PARAMETER Secret
        The Aurora DNS API secret key for your account.
    .PARAMETER Api
        The Aurora DNS API hostname.
        Default (if not specified): api.auroradns.eu
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' @auroraAuthorization
        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [String]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [String]$TxtValue,

        [Parameter(Mandatory, Position = 2)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$AuroraCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$AuroraApi = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    Write-Debug "convert the Credential to normal String values"
    $auroraAuthorization = @{ Api = $AuroraApi; Key = $AuroraCredential.UserName; Secret = $AuroraCredential.GetNetworkCredential().Password }

    Write-Debug "Attempting to find hosted zone for $RecordName"
    try {
        $zone = Invoke-AuroraFindZone -RecordName $RecordName @auroraAuthorization
        $ZoneID = $zone.id
        $zoneName = $zone.name
    } catch { Write-Debug "Caught an error, $($_.Exception.Message)"; throw }

    if ((-not $ZoneID) -or (-not $zoneName)) {
        throw "Unable to find Aurora hosted zone for $RecordName"
    }

    Write-Debug "Separate the portion of the name that doesn't contain the zone name"
    $recordPath = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    Write-Debug "[recordPath:$recordPath][RecordName:$RecordName]"

    Write-Debug "Query the existing record(s)"
    try {
        $records = @()
        $records += Invoke-AuroraGetRecord -RecordName $recordPath -ZoneID $ZoneID @auroraAuthorization
    } catch { Write-Debug "Caught an error, $($_.Exception.Message)"; throw }

    Write-Debug "Check for the value to delete"
    if ($records.Count -eq 0) {
        Write-Debug "Record $RecordName doesn't exist. Nothing to do."
        return
    } else {
        if ($TxtValue -notin $records.content) {
            Write-Debug "Records with the name $RecordName do not contain $TxtValue. Nothing to do."
        } else {
            Write-Debug "Record $RecordName with value $TxtValue must be deleted."
            $recordIDs = @(($records | Where-Object { $_.content -eq $TxtValue }).id)
            try {
                ForEach ($id in $recordIDs) {
                    $deletedRecords = Invoke-AuroraDeleteRecord -ZoneID $ZoneID -RecordId $id @auroraAuthorization
                }
            } catch { Write-Debug "Caught an error, $($_.Exception.Message)"; throw }
        }
    }
    <#
    .SYNOPSIS
        Remove a DNS TXT record from Aurora DNS.
    .DESCRIPTION
        Remove a DNS TXT record from Aurora DNS.
    .PARAMETER RecordName
        The fully qualified name of the TXT record.
    .PARAMETER TxtValue
        The value of the TXT record.
    .PARAMETER Credential
        The Key and Secret in a PSCredential (secure) parameter
    .PARAMETER Key
        The Aurora DNS API key for your account.
    .PARAMETER Secret
        The Aurora DNS API secret key for your account.
    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    .EXAMPLE
        $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' @auroraAuthorization
        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments, DontShow)]
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

function Get-AuroraDNSAuthorizationHeader {
    <#
.SYNOPSIS
    Create headers required for Aurora DNS authorization
.DESCRIPTION
    Create headers required for Aurora DNS authorization
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER Method
    The method used for this action.
    Some of the most used: 'POST', 'GET' or 'DELETE'
.PARAMETER Uri
    The Uri used for this action.
    Example: '/zones'
.PARAMETER ContentType
    The content type.
    Default value (if not specified): 'application/json; charset=UTF-8'
.EXAMPLE
    $authorizationHeader = Get-AuroraDNSAuthorizationHeader -Key XXXXXXXXXX -Secret YYYYYYYYYYYYYYYY -Method GET -Uri /zones
.NOTES
    Function Name : Invoke-AuroraFindZone
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Key,

        [Parameter(Mandatory)]
        [String]$Secret,

        [Parameter(Mandatory)]
        [String]$Method,

        [Parameter(Mandatory)]
        [String]$Uri,

        [Parameter()]
        [String]$ContentType = "application/json; charset=UTF-8",

        [Parameter(DontShow)]
        [String]$TimeStamp = $((get-date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")),

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $Message = '{0}{1}{2}' -f $Method, $Uri, $TimeStamp
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.key = [Text.Encoding]::UTF8.GetBytes($Secret)
    $Signature = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Message))
    $SignatureB64 = [Convert]::ToBase64String($signature)
    $AuthorizationString = '{0}:{1}' -f $Key, $SignatureB64
    $Authorization = [Text.Encoding]::UTF8.GetBytes($AuthorizationString)
    $AuthorizationB64 = [Convert]::ToBase64String($Authorization)

    $headers = @{
        'X-AuroraDNS-Date' = $TimeStamp
        'Authorization'    = $('AuroraDNSv1 {0}' -f $AuthorizationB64)
        'Content-Type'     = $ContentType
    }
    Write-Output $headers
}

function Invoke-AuroraAddRecord {
    <#
.SYNOPSIS
    Get Aurora DNS Record
.DESCRIPTION
    Get Aurora DNS Record
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER ZoneID
    Specify a specific Aurora DNS Zone ID (GUID).
.PARAMETER Name
    Specify a name fo the new record.
.PARAMETER Content
    Specify the content for the nwe record.
.PARAMETER TTL
    Specify a Time To Live value in seconds.
    Default (if not specified): 3600
.PARAMETER Type
    Specify the record type.
    Can contain one of the following values: "A", "AAAA", "CNAME", "MX", "NS", "SOA", "SRV", "TXT", "DS", "PTR", "SSHFP", "TLSA"
    Default (if not specified): "A"
.PARAMETER Api
    The Aurora DNS API hostname.
    Default (if not specified): api.auroradns.eu
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$record = Invoke-AuroraAddRecord -ZoneID 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -Name www -Content 198.51.100.85 @auroraAuthorization
    Create an 'A' record with the name 'www' and content '198.51.100.85'
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$record = Invoke-AuroraAddRecord -ZoneID 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -Content 'v=spf1 include:_spf.google.com' -Type TXT @auroraAuthorization
    Create an 'TXT' for the domain (no record name) and content 'v=spf1 include:_spf.google.com'
.NOTES
    Function Name : Invoke-AuroraAddRecord
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Key,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Secret,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [GUID[]]$ZoneID,

        [String]$Name = '',

        [String]$Content = '',

        [int]$TTL = 3600,

        [ValidateSet('A', 'AAAA', 'CNAME', 'MX', 'NS', 'SOA', 'SRV', 'TXT', 'DS', 'PTR', 'SSHFP', 'TLSA')]
        [String]$Type = 'A',

        [Parameter()]
        [String]$Api = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $UseBasic = @{ }
    if ('UseBasicParsing' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        $UseBasic.UseBasicParsing = $true
    }
    $Method = 'POST'
    $Uri = '/zones/{0}/records' -f $ZoneID.Guid
    $ApiUrl = 'https://{0}{1}' -f $Api, $Uri
    $AuthorizationHeader = Get-AuroraDNSAuthorizationHeader -Key $Key -Secret $Secret -Method $Method -Uri $Uri
    $restError = ''

    $Payload = @{
        name    = $Name
        ttl     = $TTL
        type    = $Type
        content = $Content
    }
    $Body = $Payload | ConvertTo-Json
    Write-Debug "$Method URI: `"$ApiUrl`""
    try {
        [Object[]]$result = Invoke-RestMethod -Uri $ApiUrl -Headers $AuthorizationHeader -Method $Method -Body $Body -ErrorVariable restError @UseBasic
    } catch {
        $result = $null
        $OutError = $restError[0].Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        Write-Debug $($OutError | Out-String)
        Throw ($OutError.errormsg)
    }
    if ( ($result.Count -gt 0) -and ($null -ne $result[0].id) -and (-not [String]::IsNullOrEmpty($($result[0].id))) ) {
        Write-Output $result
    } else {
        Write-Debug "The function generated no data"
        Write-Output $null
    }
}

function Invoke-AuroraDeleteRecord {
    <#
.SYNOPSIS
    Delete an Aurora DNS Record
.DESCRIPTION
    Delete an Aurora DNS Record
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER ZoneID
    Specify a specific Aurora DNS Zone ID (GUID).
.PARAMETER RecordID
    Specify a specific Aurora DNS Record ID (GUID).
.PARAMETER Api
    The Aurora DNS API hostname.
    Default (if not specified): api.auroradns.eu
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>Invoke-AuroraDeleteRecord -ZoneID aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee  -RecordID vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz @auroraAuthorization
    Delete a record with the ID 'vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz' in zone 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
.NOTES
    Function Name : Invoke-AuroraDeleteRecord
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Secret,

        [Parameter(Mandatory)]
        [GUID[]]$ZoneID,

        [Parameter(Mandatory)]
        [GUID[]]$RecordId,

        [Parameter()]
        [String]$Api = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $UseBasic = @{ }
    if ('UseBasicParsing' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        $UseBasic.UseBasicParsing = $true
    }
    $Method = 'DELETE'
    $Uri = '/zones/{0}/records/{1}' -f $ZoneID.Guid, $RecordId.Guid
    $ApiUrl = 'https://{0}{1}' -f $Api, $Uri
    $AuthorizationHeader = Get-AuroraDNSAuthorizationHeader -Key $Key -Secret $Secret -Method $Method -Uri $Uri
    $restError = ''

    Write-Debug "$Method URI: `"$ApiUrl`""
    try {
        $result = Invoke-RestMethod -Uri $ApiUrl -Headers $AuthorizationHeader -Method $Method -ErrorVariable restError @UseBasic
    } catch {
        $result = $null
        $OutError = $restError[0].Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        Write-Debug $($OutError | Out-String)
        Throw ($OutError.errormsg)
    }
    if ([String]::IsNullOrWhiteSpace($($result.id))) {
        Write-Debug "The function generated no data"
        Write-Output $null
    } else {
        Write-Output $result
    }
}

function Invoke-AuroraFindZone {
    <#
.SYNOPSIS
    Get Aurora DNS Zone based on full record/host name
.DESCRIPTION
    Get Aurora DNS Zone based on full record/host name
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER Api
    The Aurora DNS API hostname.
    Default (if not specified): api.auroradns.eu
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$zone = Invoke-AuroraFindZone -RecordName www.domain.com @auroraAuthorization
.NOTES
    Function Name : Invoke-AuroraFindZone
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [String]$RecordName,

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$Key,

        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [String]$Secret,

        [Parameter(Position = 3)]
        [ValidateNotNullOrEmpty()]
        [String]$Api = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $auroraAuthorization = @{ Api = $Api; Key = $Key; Secret = $Secret }
    try {
        [Object[]]$zones = Invoke-AuroraGetZones @auroraAuthorization
    } catch { Write-Debug "Caught an error, $($_.Exception.Message)"; throw }

    Write-Debug "Search for the zone from longest to shortest set of FQDN pieces"
    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            Write-Debug "Check for results"
            [Object[]]$result = @($Zones | Where-Object { $_.name -eq $zoneTest })
            if ($result.Count -gt 0) {
                Write-Output $result
            }
        } catch {
            Write-Debug "Caught an error, $($_.Exception.Message)"
            throw
        }
    }
}

function Invoke-AuroraGetRecord {
    <#
.SYNOPSIS
    Get Aurora DNS Record
.DESCRIPTION
    Get Aurora DNS Record
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER RecordID
    Specify a specific Aurora DNS Record ID (GUID).
.PARAMETER RecordName
    Specify a specific Aurora DNS Record Name (String).
.PARAMETER ZoneID
    Specify a specific Aurora DNS Zone ID (GUID).
.PARAMETER Api
    The Aurora DNS API hostname.
    Default (if not specified): api.auroradns.eu
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$record = Invoke-AuroraGetRecord -ZoneID 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' @auroraAuthorization
    List all records by not specifying 'RecordID' or 'RecordName' with a value
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$record = Invoke-AuroraGetRecord -ZoneID 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -RecordName 'www' @auroraAuthorization
    Get record with name 'www' in zone 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$record = Invoke-AuroraGetRecord -ZoneID 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -RecordID 'vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz' @auroraAuthorization
    Get record with ID 'vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz' in zone 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
.NOTES
    Function Name : Invoke-AuroraGetRecord
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Key,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Secret,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [GUID[]]$ZoneID,

        [Parameter(ParameterSetName = 'GUID', Mandatory)]
        [GUID[]]$RecordID,

        [Parameter(ParameterSetName = 'Named')]
        [String]$RecordName,

        [Parameter(ParameterSetName = 'Named')]
        [String]$Co,

        [Parameter()]
        [String]$Api = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $UseBasic = @{ }
    if ('UseBasicParsing' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        $UseBasic.UseBasicParsing = $true
    }
    $Method = 'GET'
    if ($PSCmdlet.ParameterSetName -like "GUID") {
        $Uri = '/zones/{0}/records/{1}' -f $ZoneID.Guid, $RecordID.Guid
    } else {
        $Uri = '/zones/{0}/records' -f $ZoneID.Guid
    }
    Write-Verbose "$Uri"
    $ApiUrl = 'https://{0}{1}' -f $Api, $Uri
    $AuthorizationHeader = Get-AuroraDNSAuthorizationHeader -Key $Key -Secret $Secret -Method $Method -Uri $Uri
    $restError = ''
    try {
        Write-Debug "$Method URI: `"$ApiUrl`""
        [Object[]]$result = Invoke-RestMethod -Uri $ApiUrl -Headers $AuthorizationHeader -Method $Method -ErrorVariable restError @UseBasic
        if ($PSBoundParameters.ContainsKey('distributionalgorithm')) { $Payload.Add('distributionalgorithm', $distributionalgorithm) }

        if ($PSCmdlet.ParameterSetName -like "Named") {
            [Object[]]$result = $result | Where-Object { $_.name -eq $RecordName }
        }
    } catch {
        $result = $null
        $OutError = $restError[0].Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        Write-Debug $($OutError | Out-String)
        if ($OutError.error -eq 'NoSuchRecordError') {
            $result = $null
        } else {
            Throw ($OutError.errormsg)
        }
    }
    if ( ($result.Count -gt 0) -and ($null -ne $result[0].id) -and (-not [String]::IsNullOrEmpty($($result[0].id))) ) {
        Write-Output $result
    } else {
        Write-Debug "The function generated no data"
        Write-Output $null
    }
}

function Invoke-AuroraGetZones {
    <#
.SYNOPSIS
    Get Aurora DNS Zones
.DESCRIPTION
    Get Aurora DNS Zones
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER Api
    The Aurora DNS API hostname.
    Default (if not specified): api.auroradns.eu
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$zones = Invoke-AuroraGetZones @auroraAuthorization
.NOTES
    Function Name : Invoke-AuroraGetZones
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Key,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Secret,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Api = 'api.auroradns.eu',

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $UseBasic = @{ }
    if ('UseBasicParsing' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        $UseBasic.UseBasicParsing = $true
    }
    $Method = 'GET'
    $Uri = '/zones'
    $ApiUrl = 'https://{0}{1}' -f $Api, $Uri
    $AuthorizationHeader = Get-AuroraDNSAuthorizationHeader -Key $Key -Secret $Secret -Method $Method -Uri $Uri
    $restError = ''
    Write-Debug "$Method URI: `"$ApiUrl`""
    try {
        [Object[]]$result = Invoke-RestMethod -Uri $ApiUrl -Headers $AuthorizationHeader -Method $Method -ErrorVariable restError @UseBasic
    } catch {
        $result = $null
        $OutError = $restError[0].Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        Write-Debug $($OutError | Out-String)
        Throw ($OutError.errormsg)
    }
    if ( ($result.Count -gt 0) -and ($null -ne $result[0].id) -and (-not [String]::IsNullOrEmpty($($result[0].id))) ) {
        Write-Output $result
    } else {
        Write-Debug "The function generated no data"
        Write-Output $null
    }
}

function Invoke-AuroraSetRecord {
    <#
.SYNOPSIS
    Set Aurora DNS Record with new values
.DESCRIPTION
    Get Aurora DNS Record with new values
.PARAMETER Key
    The Aurora DNS API key for your account.
.PARAMETER Secret
    The Aurora DNS API secret key for your account.
.PARAMETER ZoneID
    Specify a specific Aurora DNS Zone ID (GUID).
.PARAMETER RecordID
    Specify a specific Aurora DNS Record ID (GUID).
.PARAMETER Name
    Specify a name fo the new record.
.PARAMETER Content
    Specify the content for the nwe record.
.PARAMETER TTL
    Specify a Time To Live value in seconds.
    Default (if not specified): 3600
.PARAMETER Type
    Specify the record type.
    Can contain one of the following values: "A", "AAAA", "CNAME", "MX", "NS", "SOA", "SRV", "TXT", "DS", "PTR", "SSHFP", "TLSA"
    Default (if not specified): "A"
.PARAMETER Api
    The Aurora DNS API hostname.
    Default (if not specified): api.auroradns.eu
.EXAMPLE
    $auroraAuthorization = @{ Api='api.auroradns.eu'; Key='XXXXXXXXXX'; Secret='YYYYYYYYYYYYYYYY' }
    PS C:\>$record = Invoke-AuroraSetRecord -ZoneID 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -RecordID 'vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz' -Content 198.51.100.85 @auroraAuthorization
    Set an existing record with new content '198.51.100.85'
.NOTES
    Function Name : Invoke-AuroraAddRecord
    Version       : v2021.0530.1330
    Author        : John Billekens
    Requires      : API Account => https://cp.pcextreme.nl/auroradns/users
.LINK
    https://github.com/j81blog/Posh-AuroraDNS
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Secret,

        [Parameter(Mandatory)]
        [GUID[]]$ZoneID,

        [Parameter(Mandatory)]
        [GUID[]]$RecordId,

        [String]$Name,

        [String]$Content,

        [int]$TTL = 3600,

        [ValidateSet('A', 'AAAA', 'CNAME', 'MX', 'NS', 'SOA', 'SRV', 'TXT', 'DS', 'PTR', 'SSHFP', 'TLSA')]
        [String]$Type = 'A',

        [Parameter()]
        [String]$Api = 'api.auroradns.eu',

        [Switch]$PassThru,

        [Parameter(ValueFromRemainingArguments, DontShow)]
        $ExtraParams
    )
    $UseBasic = @{ }
    if ('UseBasicParsing' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        $UseBasic.UseBasicParsing = $true
    }
    $Method = 'PUT'
    $Uri = '/zones/{0}/records/{1}' -f $ZoneId.Guid, $RecordId.Guid
    $ApiUrl = 'https://{0}{1}' -f $Api, $Uri
    $AuthorizationHeader = Get-AuroraDNSAuthorizationHeader -Key $Key -Secret $Secret -Method $Method -Uri $Uri
    $restError = ''

    $Payload = @{ }
    if ($PSBoundParameters.ContainsKey('Name')) { $Payload.Add('name', $Name) }
    if ($PSBoundParameters.ContainsKey('TTL')) { $Payload.Add('ttl', $TTL) }
    if ($PSBoundParameters.ContainsKey('Type')) { $Payload.Add('type', $Type) }
    if ($PSBoundParameters.ContainsKey('Content')) { $Payload.Add('content', $Content) }

    $Body = $Payload | ConvertTo-Json

    Write-Debug "$Method URI: `"$ApiUrl`""
    try {
        [Object[]]$result = Invoke-RestMethod -Uri $ApiUrl -Headers $AuthorizationHeader -Method $Method -Body $Body -ErrorVariable restError @UseBasic
        if ($PassThru -and (($result.Count -eq 0) -or ([string]::IsNullOrWhiteSpace($result)))) {
            [Object[]]$result = Invoke-AuroraGetRecord -ZoneID $ZoneID -RecordID $RecordID -Key $Key -Secret $Secret -Api $Api
        }
    } catch {
        $result = $null
        $OutError = $restError[0].Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        Write-Debug $($OutError | Out-String)
        Throw ($OutError.errormsg)
    }
    if ( ($result.Count -gt 0) -and ($null -ne $result[0].id) -and (-not [String]::IsNullOrEmpty($($result[0].id))) ) {
        Write-Output $result
    } else {
        Write-Debug "The function generated no data"
        Write-Output $null
    }
}
