function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [SecureString]$CombellApiKey,
        [Parameter(Mandatory, Position = 3)]
        [SecureString]$CombellApiSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Convert the SecureString parameters to type String.
    $ApiKey = [pscredential]::new('a', $CombellApiKey).GetNetworkCredential().Password
    $ApiSecret = [pscredential]::new('a', $CombellApiSecret).GetNetworkCredential().Password

    $cmdletName = "Add-DnsTxt"
    $zoneName = Find-CombellZone $RecordName $ApiKey $ApiSecret
    Write-Verbose "${cmdletName}: Find domain '$zoneName' for record '$RecordName' - OK"
    $relativeRecordName = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    $txtRecords = Get-CombellTxtRecords $zoneName $relativeRecordName $TxtValue $ApiKey $ApiSecret
    $numberOfTxtRecords = $txtRecords.Length

    if ($numberOfTxtRecords -gt 0) {
        Write-Verbose "${cmdletName}: Domain '$zoneName' contains $numberOfTxtRecords TXT record$(if ($numberOfTxtRecords -gt 1) { "s" }) that match$(if ($numberOfTxtRecords -eq 1) { "es" }) record name ""$relativeRecordName"" and content ""$TxtValue""; abort."
        return
    }

    Write-Verbose "${cmdletName}: Domain '$zoneName' contains 0 TXT records that match record name ""$relativeRecordName"" and content ""$TxtValue""; add TXT record { ""record_name"": ""$relativeRecordName"", ""content"": ""$TxtValue"" }."
    $requestBody = @{
        type        = "TXT"
        record_name = $relativeRecordName
        ttl         = 60
        content     = $TxtValue
    } | ConvertTo-Json -Compress

    Send-CombellHttpRequest POST "dns/$zoneName/records" $ApiKey $ApiSecret $requestBody | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record via the Combell API.

    .DESCRIPTION
        Add a DNS TXT record via the Combell API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CombellApiKey
        The Combell API key associated with your account.

    .PARAMETER CombellApiSecret
        The Combell API secret associated with your account.

   .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this
        function supports.

    .EXAMPLE
        $combellApiKey = Read-Host "Combell API key" -AsSecureString
        $combellApiSecret = Read-Host "Combell API secret" -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $combellApiKey $combellApiSecret

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [SecureString]$CombellApiKey,
        [Parameter(Mandatory, Position = 3)]
        [SecureString]$CombellApiSecret,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Convert the SecureString parameters to type String.
    $ApiKey = [pscredential]::new('a', $CombellApiKey).GetNetworkCredential().Password
    $ApiSecret = [pscredential]::new('a', $CombellApiSecret).GetNetworkCredential().Password

    $cmdletName = "Remove-DnsTxt"
    $zoneName = Find-CombellZone $RecordName $ApiKey $ApiSecret
    Write-Verbose "${cmdletName}: Find domain '$zoneName' for record '$RecordName' - OK"
    $relativeRecordName = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''
    $txtRecords = Get-CombellTxtRecords $zoneName $relativeRecordName $TxtValue $ApiKey $ApiSecret
    $numberOfTxtRecords = $txtRecords.Length

    if ($numberOfTxtRecords -eq 0) {
        Write-Verbose "${cmdletName}: Domain '$zoneName' contains 0 TXT records that match record name '$relativeRecordName' and content ""$TxtValue""; abort."
        return
    }

    Write-Verbose "${cmdletName}: Domain '$zoneName' contains $numberOfTxtRecords TXT record$(if ($numberOfTxtRecords -gt 1) { "s" }) that match$(if ($numberOfTxtRecords -eq 1) { "es" }) record name '$relativeRecordName' and content ""$TxtValue""; delete $numberOfTxtRecords record$(if ($numberOfTxtRecords -gt 1) { "s" })."

    foreach ($txtRecord in $txtRecords) {
        Write-Verbose "${cmdletName}: Delete TXT record $txtRecord"
        Send-CombellHttpRequest DELETE "dns/$zoneName/records/$($txtRecord.id)" $ApiKey $ApiSecret | Out-Null
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record via the Combell API.

    .DESCRIPTION
        Remove a DNS TXT record via the Combell API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CombellApiKey
        The Combell API key associated with your account.

    .PARAMETER CombellApiSecret
        The Combell API secret associated with your account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this
        function supports.

    .EXAMPLE
        $combellApiKey = Read-Host "Combell API key" -AsSecureString
        $combellApiSecret = Read-Host "Combell API secret" -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $combellApiKey $combellApiSecret

        Removes a TXT record for the specified site with the specified value. If multiple records exist with the same
        record name and the same content, this cmdlet deletes all of them.
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
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this
        function supports.
    #>
}

############################
# Helper Functions
############################

function Find-CombellZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$ApiKey,
        [Parameter(Mandatory, Position = 2)]
        [string]$ApiSecret
    )

    # Setup a module variable to cache the record to zone mapping, so it's quicker to find later.
    if (!$script:CombellRecordZones) {
        $script:CombellRecordZones = @{}
    }

    # If the cache contains $RecordName, return it.
    if ($script:CombellRecordZones.ContainsKey($RecordName)) {
        return $script:CombellRecordZones.$RecordName
    }

    # Not specifying the 'take' query parameter defaults the result set to a maximum 25 items (situation on 30
    # September 2021). It is not clear from the documentation how you can get all domains in a single request, so I'm
    # defaulting here to a 'take' parameter value of '1000'.
    # If you find a better solution, feel free to submit an issue.
    # See https://api.combell.com/v2/documentation#operation/Domains for more information.
    # - Steven Volckaert, 30 September 2021.
    # TODO Although undocumented, it appears it might be possible to retrieve the total number of domains from some
    #      custom HTTP response headers. So: Consider removing the 'take' query parameter, which will default back to
    #      maximum 25 items per response, and sending addtional HTTP requests if the HTTP header(s) indicate that more
    #      domains exist.
    #      Implementing this requires further investigation though (start by reading
    #      https://api.combell.com/v2/documentation#section/Conventions/Pagination), so if you need this, feel free to
    #      submit a pull request or an issue - Steven Volckaert, 5 October 2021.
    $zones = Send-CombellHttpRequest GET "domains?take=1000" $ApiKey $ApiSecret;

    # We need to find the deepest sub-zone that can hold the record and add it there, except if there is only the apex
    # zone. So for a $RecordName like _acme-challenge.site1.sub1.sub2.example.com, we need to search the zone from
    # longest to shortest set of FQDNs contained in $zones, i.e. in the following order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com
    # See https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/#zone-matching for more information.
    # - Steven Volckaert, 30 September 2021.
    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        Write-Verbose "Find domain '$zoneTest' in $($zones.Length) Combell domains"
        if ($zoneTest -in $zones.domain_name) {
            $zone = $zones | Where-Object { $_.domain_name -eq $zoneTest }
            $script:CombellRecordZones.$RecordName = $zone.domain_name
            return $zone.domain_name
        }
    }

    throw "FATAL: No domain zone found for record '$RecordName'."
}

function Get-CombellAuthorizationHeaderValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ApiKey,
        [Parameter(Mandatory, Position = 1)]
        [string]$ApiSecret,
        [Parameter(Mandatory, Position = 2)]
        [string]$Method,
        [Parameter(Mandatory, Position = 3)]
        [string]$Path,
        [Parameter(Position = 4)]
        [string]$Body
    )

    $urlEncodedPath = [System.Net.WebUtility]::UrlEncode("/v2/$Path")
    $unixTimestamp = [System.DateTimeOffset]::Now.ToUnixTimeSeconds().ToString()
    $nonce = (New-Guid).ToString()
    $hmacInputValue = "${ApiKey}$($Method.ToLowerInvariant())${urlEncodedPath}${unixTimestamp}${nonce}"

    if ($Body) {
        $md5Algorithm = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
        $bodyAsByteArray = [Text.Encoding]::UTF8.GetBytes($Body)
        $bodyAsHashedBase64String = [Convert]::ToBase64String($md5Algorithm.ComputeHash($bodyAsByteArray))
        $hmacInputValue += $bodyAsHashedBase64String
    }

    $hmacAlgorithm = New-Object System.Security.Cryptography.HMACSHA256
    $hmacAlgorithm.Key = [Text.Encoding]::UTF8.GetBytes($ApiSecret)
    $hmacInputValueAsByteArray = [Text.Encoding]::UTF8.GetBytes($hmacInputValue)
    $hmacSignature = [Convert]::ToBase64String($hmacAlgorithm.ComputeHash($hmacInputValueAsByteArray))

    return "hmac ${ApiKey}:${hmacSignature}:${nonce}:${unixTimestamp}"

    <#
    .SYNOPSIS
        Gets the value of the Authorization header.
        See https://api.combell.com/v2/documentation#section/Authentication for more information.
    #>
}

function Get-CombellTxtRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$DomainName,
        [Parameter(Mandatory, Position = 1)]
        [string]$RelativeRecordName,
        [Parameter(Mandatory, Position = 2)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 3)]
        [string]$ApiKey,
        [Parameter(Mandatory, Position = 4)]
        [string]$ApiSecret
    )

    $txtRecords = Send-CombellHttpRequest `
        GET "dns/$DomainName/records?type=TXT&record_name=$RelativeRecordName" $ApiKey $ApiSecret
    return @($txtRecords | Where-Object { $_.record_name -eq $RelativeRecordName -and $_.content -ceq $TxtValue })
}

function Send-CombellHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('GET', 'PUT', 'POST', 'DELETE')]
        [string]$Method,
        [Parameter(Mandatory, Position = 1)]
        [string]$Path,
        [Parameter(Mandatory, Position = 2)]
        [string]$ApiKey,
        [Parameter(Mandatory, Position = 3)]
        [string]$ApiSecret,
        [Parameter(Position = 4)]
        [string]$Body
    )

    $uri = [uri]"https://api.combell.com/v2/$Path"
    $authorizationHeaderValue = Get-CombellAuthorizationHeaderValue $ApiKey $ApiSecret $Method $Path $Body

    $headers = @{
        Accept        = 'application/json'
        Authorization = $authorizationHeaderValue
    }
    $invokeRestMesthodParameters = @{
        Method             = $Method
        Uri                = $uri
        Headers            = $headers
        ContentType        = 'application/json'
        MaximumRedirection = 0
        ErrorAction        = 'Stop'
    }
    if ($Body) {
        $invokeRestMesthodParameters.Body = $Body
    }

    try {
        $Stopwatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $Stopwatch.Start()
        Invoke-RestMethod @invokeRestMesthodParameters @script:UseBasic
        $Stopwatch.Stop()
        Write-Verbose "$Method $uri - OK ($($Stopwatch.ElapsedMilliseconds) ms)"
    }
    catch {
        $Stopwatch.Stop()
        Write-Error "$Method $uri - FAILED ($($Stopwatch.ElapsedMilliseconds) ms) - $($_)"
        throw
    }
}
