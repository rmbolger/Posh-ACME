# [Writing a Validation Plugin for Posh-ACME](https://poshac.me/docs/v4/Plugins/Plugin-Development-Guide/)
#
# Tips for developing this plugin
# 1) 'dot source' the Combell.ps1 plugin:
# 
#     PS C:\Users\Steven Volckaert\Repos\stevenvolckaert\Posh-ACME\Posh-ACME\Plugins> . .\Combell.ps1
#
#  So: Add ". .\Combell.ps1" before every command:
#
#    PS C:\Users\Steven Volckaert\Repos\stevenvolckaert\Posh-ACME\Posh-ACME\Plugins> . .\Combell.ps1 ; Get-DnsRecords "skardev.com" -Verbose
#

function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ParameterSetName = 'Secure', Mandatory)]
        [securestring]$CombellApiKey,
        [Parameter(ParameterSetName = 'Insecure', Mandatory)]
        [string]$CombellApiKeyInsecure,
        [Parameter(ParameterSetName = 'Secure', Mandatory)]
        [securestring]$CombellApiSecret,
        [Parameter(ParameterSetName = 'Insecure', Mandatory)]
        [string]$CombellApiSecretInsecure,
        <##>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # $RecordName contains the fully qualified domain name (FQDN); use it to get the domain name


    # Docs @ https://api.combell.com/v2/documentation#tag/DNS-records/paths/~1dns~1{domainName}~1records/post

    $txtRecords = Send-CombellHttpRequest `
        -ApiKey $ApiKey `
        -ApiSecret $ApiSecret `
        -Method "GET" `
        -Path "dns/$DomainName/records?type=TXT&record_name=$RecordName" `
    | Where-Object { $_.record_name -eq $RecordName };
    $txtRecords = $txtRecords | Where-Object { $_.record_name -eq $RecordName };
    $numberOfTxtRecords = ($txtRecords | Measure-Object).Count;

    if ($numberOfTxtRecords -eq 0) {
        Write-Verbose "Domain ""$DomainName"" contains 0 TXT records that match record name ""$RecordName""; add TXT record { ""record_name"": ""$RecordName"", ""content"": ""$TxtValue"" }."
        $requestBody = @{
            type        = "TXT"
            record_name = $RecordName
            ttl         = 60
            content     = "$TxtValue"
        } | ConvertTo-Json -Compress
        Write-Verbose "requestBody: $requestBody";

        Send-CombellHttpRequest `
            -ApiKey $ApiKey `
            -ApiSecret $ApiSecret `
            -Body $requestBody `
            -Method "POST" `
            -Path "dns/$DomainName/records" | Out-Null;

        $txtRecords = Send-CombellHttpRequest `
            -ApiKey $ApiKey `
            -ApiSecret $ApiSecret `
            -Method "GET" `
            -Path "dns/$DomainName/records?type=TXT&record_name=$RecordName" | Out-Null;

        return;
    }   

    $txtRecordToUpdate = $txtRecords | Select-Object -First 1;
    $txtRecordDisplayName = "{ ""id"": ""$($txtRecordToUpdate.id)"", ""record_name"": ""$($txtRecordToUpdate.record_name)"", ""content"": ""$($txtRecordToUpdate.content)"" }";
    Write-Verbose "Domain ""$DomainName"" contains $numberOfTxtRecords TXT record$(if ($numberOfTxtRecords -gt 1) { "s" }) that match$(if ($numberOfTxtRecords -eq 1) { "es" }) record name ""$RecordName""; update TXT record $txtRecordDisplayName with { ""content"": ""$TxtValue"" }."

    if ($txtRecordToUpdate.content -ceq $TxtValue) {
        Write-Verbose "TXT record $txtRecordDisplayName already has { ""content"": ""$TxtValue"" }; abort.";
        return;
    }

    $requestBody = @{
        type        = "TXT"
        record_name = $RecordName
        ttl         = 60
        content     = $TxtValue
    } | ConvertTo-Json -Compress;

    Send-CombellHttpRequest `
        -ApiKey $ApiKey `
        -ApiSecret $ApiSecret `
        -Body $requestBody `
        -Method "PUT" `
        -Path "dns/$DomainName/records/$($txtRecordToUpdate.id)" | Out-Null;


    # Do work here to add the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Add a DNS TXT record via the Combell API.

    .DESCRIPTION
        Add a DNS TXT record via the Combell API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Adds a TXT record for the specified site with the specified value.
    #>
}

# This function is provided only for testing purposes, it should probably be deleted when the plugin is ready.
# See https://api.combell.com/v2/documentation#tag/DNS-records/paths/~1dns~1{domainName}~1records/get for
# API documentation - Steven Volckaert, 29 September 2021.
function Get-DnsRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$DomainName,
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$ApiSecret
    )

    Write-Verbose "-DomainName: ""$DomainName""";
    Send-CombellHttpRequest `
        -ApiKey $ApiKey `
        -ApiSecret $ApiSecret `
        -Method "GET" `
        -Path "dns/$DomainName/records"
}

function Add-DnsTxtTestRecord {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$DomainName = "skardev.com",
        [Parameter(Position = 1)]
        [string]$RecordName = "_acme-challenge",
        [Parameter(Position = 2)]
        [string]$TxtValue = "loremipsum",
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$ApiSecret
    )

    $txtRecords = Send-CombellHttpRequest `
        -ApiKey $ApiKey `
        -ApiSecret $ApiSecret `
        -Method "GET" `
        -Path "dns/$DomainName/records?type=TXT&record_name=$RecordName";
    $txtRecords = $txtRecords | Where-Object { $_.record_name -eq $RecordName };
    $numberOfTxtRecords = ($txtRecords | Measure-Object).Count;

    if ($numberOfTxtRecords -eq 0) {
        Write-Verbose "Domain ""$DomainName"" contains 0 TXT records that match record name ""$RecordName""; add TXT record { ""record_name"": ""$RecordName"", ""content"": ""$TxtValue"" }."
        $requestBody = @{
            type        = "TXT"
            record_name = $RecordName
            ttl         = 60
            content     = "$TxtValue"
        } | ConvertTo-Json -Compress
        Write-Verbose "requestBody: $requestBody";

        Send-CombellHttpRequest `
            -ApiKey $ApiKey `
            -ApiSecret $ApiSecret `
            -Body $requestBody `
            -Method "POST" `
            -Path "dns/$DomainName/records" | Out-Null;

        $txtRecords = Send-CombellHttpRequest `
            -ApiKey $ApiKey `
            -ApiSecret $ApiSecret `
            -Method "GET" `
            -Path "dns/$DomainName/records?type=TXT&record_name=$RecordName" | Out-Null;

        return;
    }   

    $txtRecordToUpdate = $txtRecords | Select-Object -First 1;
    $txtRecordDisplayName = "{ ""id"": ""$($txtRecordToUpdate.id)"", ""record_name"": ""$($txtRecordToUpdate.record_name)"", ""content"": ""$($txtRecordToUpdate.content)"" }";
    Write-Verbose "Domain ""$DomainName"" contains $numberOfTxtRecords TXT record$(if ($numberOfTxtRecords -gt 1) { "s" }) that match$(if ($numberOfTxtRecords -eq 1) { "es" }) record name ""$RecordName""; update TXT record $txtRecordDisplayName with { ""content"": ""$TxtValue"" }."

    if ($txtRecordToUpdate.content -ceq $TxtValue) {
        Write-Verbose "TXT record $txtRecordDisplayName already has { ""content"": ""$TxtValue"" }; abort.";
        return;
    }
    
    $requestBody = @{
        type        = "TXT"
        record_name = $RecordName
        ttl         = 60
        content     = $TxtValue
    } | ConvertTo-Json -Compress;

    Send-CombellHttpRequest `
        -ApiKey $ApiKey `
        -ApiSecret $ApiSecret `
        -Body $requestBody `
        -Method "PUT" `
        -Path "dns/$DomainName/records/$($txtRecordToUpdate.id)" | Out-Null;
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ParameterSetName = 'Secure', Mandatory)]
        [securestring]$CombellApiKey,
        [Parameter(ParameterSetName = 'Insecure', Mandatory)]
        [string]$CombellApiKeyInsecure,
        [Parameter(ParameterSetName = 'Secure', Mandatory)]
        [securestring]$CombellApiSecret,
        [Parameter(ParameterSetName = 'Insecure', Mandatory)]
        [string]$CombellApiSecretInsecure,
        <##>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # TODO convert securestring to normal string, if provided

    $zoneName = Find-CombellZone $RecordName $CombellApiKeyInsecure $CombellApiSecretInsecure
    Write-Verbose "Found domain zone ""$zoneName"" for record ""$RecordName"".";
    $shortRecordName = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    Write-Verbose "Short record name: ""$shortRecordName""";

    $txtRecords = Send-CombellHttpRequest `
        -ApiKey $CombellApiKeyInsecure `
        -ApiSecret $CombellApiSecretInsecure `
        -Method GET `
        -Path "dns/$zoneName/records?type=TXT&record_name=$shortRecordName";
    $txtRecords = $txtRecords | Where-Object { $_.record_name -eq $shortRecordName -and $_.content -ceq $TxtValue };
    $numberOfTxtRecords = ($txtRecords | Measure-Object).Count;

    if ($numberOfTxtRecords -eq 0) {
        Write-Verbose "Domain ""$zoneName"" contains 0 TXT records that match record name ""$shortRecordName""; abort."
        return;
    }

    Write-Verbose "Domain ""$zoneName"" contains $numberOfTxtRecords TXT record$(if ($numberOfTxtRecords -gt 1) { "s" }) that match$(if ($numberOfTxtRecords -eq 1) { "es" }) record name ""$shortRecordName"" and content ""$TxtValue""; delete $numberOfTxtRecords record$(if ($numberOfTxtRecords -gt 1) { "s" })."

    foreach ($txtRecord in $txtRecords) {
        Write-Verbose "Delete TXT record $txtRecord";
        Send-CombellHttpRequest `
            -ApiKey $CombellApiKeyInsecure `
            -ApiSecret $CombellApiSecretInsecure `
            -Method DELETE `
            -Path "dns/$zoneName/records/$($txtRecord.id)" | Out-Null;
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Removes a TXT record for the specified site with the specified value.
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

function Get-HMACSHA256Hash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Key,
        [Parameter(Mandatory, Position = 1)]
        [string]$Message
    )

    $hashAlgorithm = New-Object System.Security.Cryptography.HMACSHA256
    $hashAlgorithm.Key = [Text.Encoding]::ASCII.GetBytes($Key)
    $messageAsByteArray = [Text.Encoding]::ASCII.GetBytes($Message)
    return [Convert]::ToBase64String($hashAlgorithm.ComputeHash($messageAsByteArray))
}

function Get-MD5Hash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message
    )

    $hashAlgorithm = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
    $messageAsByteArray = [Text.Encoding]::ASCII.GetBytes($Message)
    return [Convert]::ToBase64String($hashAlgorithm.ComputeHash($messageAsByteArray))
}

function Send-CombellHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [Parameter(Position = 1)]
        [ValidateSet('GET', 'PUT', 'POST', 'DELETE')]
        [string]$Method = 'GET',
        [string]$Body,
        [string]$AcceptHeader = 'application/json',
        [string]$ApiHost = 'api.combell.com',
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$ApiSecret
    )

    $uri = [uri]"https://$($ApiHost)/v2/$Path"
    $urlEncodedPath = [System.Net.WebUtility]::UrlEncode("/v2/$Path");
    $unixTimestamp = [int][double]::Parse((Get-Date -UFormat %s));
    $nonce = (New-Guid).ToString()

    # Docs @ https://api.combell.com/v2/documentation#section/Authentication
    $hmacInputValue = "${ApiKey}$($Method.ToLowerInvariant())${urlEncodedPath}${unixTimestamp}${nonce}";

    if ($Body) {
        $hmacInputValue += Get-MD5Hash $Body;
    }

    $hmacSignature = Get-HMACSHA256Hash $ApiSecret $hmacInputValue;
    $authorizationHeaderValue = "hmac ${ApiKey}:${hmacSignature}:${nonce}:${unixTimestamp}";
    $headers = @{
        Authorization = $authorizationHeaderValue
        Accept        = $AcceptHeader
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
        $Stopwatch = New-Object -TypeName System.Diagnostics.Stopwatch;
        $Stopwatch.Start();
        Invoke-RestMethod @invokeRestMesthodParameters #@script:UseBasic
        $Stopwatch.Stop();
        Write-Verbose "$Method $uri - OK ($($Stopwatch.ElapsedMilliseconds) ms)"
    }
    catch {
        $Stopwatch.Stop();
        Write-Verbose "$Method $uri - $($_.Exception.Response.StatusCode.value__) $($_.Exception.StatusDescription) ($($Stopwatch.ElapsedMilliseconds) ms) - $($_)"

        throw

        # TODO Ignore 404

        # ignore 404 errors and just return $null
        # otherwise, let it through
        #if ([Net.HttpStatusCode]::NotFound -eq $_.Exception.Response.StatusCode) {
        #    return $null
        #}
        #else { throw }
    }
}

function Find-CombellZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$CombellApiKeyInsecure,
        [Parameter(Mandatory, Position = 2)]
        [string]$CombellApiSecretInsecure
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
    try {
        $zones = Send-CombellHttpRequest `
            -ApiKey $CombellApiKeyInsecure `
            -ApiSecret $CombellApiSecretInsecure `
            -Method GET `
            -Path "domains?take=1000";
    }
    catch { throw }

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
        Write-Verbose "Checking $zoneTest"
        if ($zoneTest -in $zones.domain_name) {
            $zone = $zones | Where-Object { $_.domain_name -eq $zoneTest }
            $script:CombellRecordZones.$RecordName = $zone.domain_name
            return $zone.domain_name
        }
    }

    throw "No domain zone found for ""$RecordName"".";
}

function Get-CombellDomains {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ApiKey,
        [Parameter(Mandatory, Position = 0)]
        [string]$ApiSecret
    )

    $domains = Send-CombellHttpRequest -ApiKey $ApiKey -ApiSecret $ApiSecret -Method GET -Path "domains?take=1000";
    $domains;
}

function Get-CombellDnsRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$DomainName,
        [string]$RecordType = $null,
        [string]$ApiKey,
        [string]$ApiSecret
    )

    # Docs @ https://api.combell.com/v2/documentation#tag/DNS-records/paths/~1dns~1{domainName}~1records/get
    # HTTP GET https://api.combell.com/v2/dns/{domainName}/records?type=$RecordType

    $requestPath = "dns/$DomainName/records";
    if ([string]::IsNullOrEmpty($RecordType) -eq $false) {
        $requestPath += "?type=$RecordType";
    }
    Write-Verbose "HTTP GET $requestPath";

    $response = Send-CombellHttpRequest $requestPath -Method GET -ApiKey $ApiKey -ApiSecret $ApiSecret;

    # TODO Print $response to output
    $response | Format-List;

    <#
    .SYNOPSIS
        Gets the DNS records of the specified domain name.
    #>
}
