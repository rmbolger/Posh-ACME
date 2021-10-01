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
        [Parameter(Mandatory, ParameterSetName = 'Secure', Position = 2)]
        [SecureString]$CombellApiKey,
        [Parameter(Mandatory, ParameterSetName = 'Insecure', Position = 2)]
        [string]$CombellApiKeyInsecure,
        [Parameter(Mandatory, ParameterSetName = 'Secure', Position = 3)]
        [SecureString]$CombellApiSecret,
        [Parameter(Mandatory, ParameterSetName = 'Insecure', Position = 3)]
        [string]$CombellApiSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Convert the SecureString parameters in the 'Secure' parameter set name to type string.
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $CombellApiKeyInsecure = (New-Object PSCredential ("userName", $CombellApiKey)).GetNetworkCredential().Password;
        $CombellApiSecretInsecure = (New-Object PSCredential ("userName", $CombellApiSecret)).GetNetworkCredential().Password;
    }

    $zoneName = Find-CombellZone $RecordName $CombellApiKeyInsecure $CombellApiSecretInsecure;
    Write-Verbose "Found domain zone ""$zoneName"" for record ""$RecordName"".";
    $shortRecordName = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.');
    $txtRecords = Get-CombellTxtRecords $zoneName $shortRecordName $CombellApiKeyInsecure $CombellApiSecretInsecure;
    $numberOfTxtRecords = $txtRecords.Length;

    if ($numberOfTxtRecords -eq 0) {
        Write-Verbose "Domain ""$zoneName"" contains 0 TXT records that match record name ""$shortRecordName""; add TXT record { ""record_name"": ""$shortRecordName"", ""content"": ""$TxtValue"" }."
        $requestBody = @{
            type        = "TXT"
            record_name = $shortRecordName
            ttl         = 60
            content     = $TxtValue
        } | ConvertTo-Json -Compress

        Send-CombellHttpRequest `
            -ApiKey $CombellApiKeyInsecure `
            -ApiSecret $CombellApiSecretInsecure `
            -Body $requestBody `
            -Method POST `
            -Path "dns/$zoneName/records" | Out-Null;

        return;
    }

    $txtRecordToUpdate = $txtRecords | Select-Object -First 1;   
    $txtRecordDisplayName = "{ ""id"": ""$($txtRecordToUpdate.id)"", ""record_name"": ""$($txtRecordToUpdate.record_name)"", ""content"": ""$($txtRecordToUpdate.content)"" }";
    Write-Verbose "Domain ""$zoneName"" contains $numberOfTxtRecords TXT record$(if ($numberOfTxtRecords -gt 1) { "s" }) that match$(if ($numberOfTxtRecords -eq 1) { "es" }) record name ""$shortRecordName""; update TXT record $txtRecordDisplayName with { ""content"": ""$TxtValue"" }."

    if ($txtRecordToUpdate.content -ceq $TxtValue) {
        Write-Verbose "TXT record $txtRecordDisplayName already has { ""content"": ""$TxtValue"" }; abort.";
        return;
    }

    $requestBody = @{
        type        = "TXT"
        record_name = $shortRecordName
        ttl         = 60
        content     = $TxtValue
    } | ConvertTo-Json -Compress;

    Send-CombellHttpRequest `
        -ApiKey $CombellApiKeyInsecure `
        -ApiSecret $CombellApiSecretInsecure `
        -Body $requestBody `
        -Method PUT `
        -Path "dns/$zoneName/records/$($txtRecordToUpdate.id)" | Out-Null;

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
        The Combell API key associated with your account. This SecureString version should only be used on Windows.

    .PARAMETER CombellApiKeyInsecure
        The Combell API key associated with your account. Use this String version on non-Windows operating systems.

    .PARAMETER CombellApiSecret
        The Combell API secret associated with your account. This SecureString version should only be used on Windows.

    .PARAMETER CombellApiKeyInsecure
        The Combell API secret associated with your account. Use this String version on non-Windows operating systems.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

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
        [Parameter(Mandatory, ParameterSetName = 'Secure', Position = 2)]
        [SecureString]$CombellApiKey,
        [Parameter(Mandatory, ParameterSetName = 'Insecure', Position = 2)]
        [string]$CombellApiKeyInsecure,
        [Parameter(Mandatory, ParameterSetName = 'Secure', Position = 3)]
        [SecureString]$CombellApiSecret,
        [Parameter(Mandatory, ParameterSetName = 'Insecure', Position = 3)]
        [string]$CombellApiSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Convert the SecureString parameters in the 'Secure' parameter set name to type string.
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $CombellApiKeyInsecure = (New-Object PSCredential ("userName", $CombellApiKey)).GetNetworkCredential().Password;
        $CombellApiSecretInsecure = (New-Object PSCredential ("userName", $CombellApiSecret)).GetNetworkCredential().Password;
    }

    $zoneName = Find-CombellZone $RecordName $CombellApiKeyInsecure $CombellApiSecretInsecure;
    Write-Verbose "Found domain zone ""$zoneName"" for record ""$RecordName"".";
    $shortRecordName = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.');
    $txtRecords = Get-CombellTxtRecords $zoneName $shortRecordName $CombellApiKeyInsecure $CombellApiSecretInsecure `
    | Where-Object { $_.content -ceq $TxtValue };
    $numberOfTxtRecords = $txtRecords.Length;

    if ($numberOfTxtRecords -eq 0) {
        Write-Verbose "Domain ""$zoneName"" contains 0 TXT records that match record name ""$shortRecordName"" and content ""$TxtValue""; abort."
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

    .PARAMETER CombellApiKey
        The Combell API key associated with your account. This SecureString version should only be used on Windows.

    .PARAMETER CombellApiKeyInsecure
        The Combell API key associated with your account. Use this String version on non-Windows operating systems.

    .PARAMETER CombellApiSecret
        The Combell API secret associated with your account. This SecureString version should only be used on Windows.

    .PARAMETER CombellApiKeyInsecure
        The Combell API secret associated with your account. Use this String version on non-Windows operating systems.

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

    $urlEncodedPath = [System.Net.WebUtility]::UrlEncode("/v2/$Path");
    $unixTimestamp = [int][double]::Parse((Get-Date -UFormat %s));
    $nonce = (New-Guid).ToString();
    $hmacInputValue = "${ApiKey}$($Method.ToLowerInvariant())${urlEncodedPath}${unixTimestamp}${nonce}";

    if ($Body) {
        $md5Algorithm = New-Object System.Security.Cryptography.MD5CryptoServiceProvider;
        $bodyAsByteArray = [Text.Encoding]::ASCII.GetBytes($Body);
        $bodyAsHashedBase64String = [Convert]::ToBase64String($md5Algorithm.ComputeHash($bodyAsByteArray));
        $hmacInputValue += $bodyAsHashedBase64String;
    }

    $hmacAlgorithm = New-Object System.Security.Cryptography.HMACSHA256;
    $hmacAlgorithm.Key = [Text.Encoding]::ASCII.GetBytes($ApiSecret);
    $hmacInputValueAsByteArray = [Text.Encoding]::ASCII.GetBytes($hmacInputValue);
    $hmacSignature = [Convert]::ToBase64String($hmacAlgorithm.ComputeHash($hmacInputValueAsByteArray));

    return "hmac ${ApiKey}:${hmacSignature}:${nonce}:${unixTimestamp}";

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
        [string]$ShortRecordName,
        [Parameter(Mandatory, Position = 2)]
        [string]$CombellApiKeyInsecure,
        [Parameter(Mandatory, Position = 3)]
        [string]$CombellApiSecretInsecure
    )

    $txtRecords = Send-CombellHttpRequest `
        -ApiKey $CombellApiKeyInsecure `
        -ApiSecret $CombellApiSecretInsecure `
        -Method GET `
        -Path "dns/$DomainName/records?type=TXT&record_name=$ShortRecordName";

    return @($txtRecords | Where-Object { $_.record_name -eq $ShortRecordName });
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
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$ApiSecret
    )

    $uri = [uri]"https://api.combell.com/v2/$Path";
    $authorizationHeaderValue = Get-CombellAuthorizationHeaderValue $ApiKey $ApiSecret $Method $Path $Body;

    $headers = @{
        Authorization = $authorizationHeaderValue
        Accept        = "application/json"
    }
    $invokeRestMesthodParameters = @{
        Method             = $Method
        Uri                = $uri
        Headers            = $headers
        ContentType        = "application/json"
        MaximumRedirection = 0
        ErrorAction        = "Stop"
    }
    if ($Body) {
        $invokeRestMesthodParameters.Body = $Body
    }

    try {
        $Stopwatch = New-Object -TypeName System.Diagnostics.Stopwatch;
        $Stopwatch.Start();
        Invoke-RestMethod @invokeRestMesthodParameters -UseBasicParsing #@script:UseBasic
        $Stopwatch.Stop();
        Write-Verbose "$Method $uri - OK ($($Stopwatch.ElapsedMilliseconds) ms)";
    }
    catch {
        $Stopwatch.Stop();
        Write-Error "$Method $uri - $($_) ($($Stopwatch.ElapsedMilliseconds) ms)";
        throw;
    }
}
