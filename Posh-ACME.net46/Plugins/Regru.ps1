function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$RegRuCredential,
        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$RegRuLogin,
        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$RegRuPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $RegRuLogin = $RegRuCredential.UserName
        $RegRuPwdInsecure = $RegRuCredential.GetNetworkCredential().Password
    }

    try {
        Write-Verbose "Searching for existing TXT record"
        $zoneName, $recShort, $recExists = Get-RrTxtRecord $RecordName $TxtValue $RegRuLogin $RegRuPwdInsecure
    }
    catch { throw }

    if ($recExists) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # Add new TXT record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        $apiBase = 'https://api.reg.ru/api/regru2/zone/'

        $bodyParams = @{
            username            = $RegRuLogin
            password            = $RegRuPwdInsecure
            domains             = @( @{ dname = $zoneName } )
            subdomain           = $recShort
            text                = $TxtValue
            output_content_type = 'plain'
        }
        $queryUri = '{0}add_txt?input_format=json&input_data={1}' -f $apiBase,(ConvertTo-RrBody $bodyParams)
        $bodyParams.password = 'XXXXXXXX'
        $querySanitized = '{0}add_txt?input_format=json&input_data={1}' -f $apiBase,(ConvertTo-RrBody $bodyParams)

        try {
            Write-Debug "GET $querySanitized"
            $response = Invoke-RestMethod $queryUri -EA Stop -Verbose:$false @script:UseBasic
            if ($response) { Write-Debug "Response:`n$(($response | ConvertTo-Json -Depth 10))" }
        }
        catch { throw }

        if ($response.result -ne 'success') {
            throw "Reg.ru API call failed adding record: $($response.error_text)"
        }

        $zoneObject = $($response.answer.domains | Where-Object { $_.dname -eq $zoneName })
        if ($zoneObject.result -ne 'success') {
            throw "$zoneName has error: $($zoneObject.error_text)"
        }
    }

    <#
     .SYNOPSIS
        Remove a DNS TXT record from Reg.Ru.

    .DESCRIPTION
        Uses the Reg.Ru API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RegRuCredential
        Your Reg.Ru username and either account password or API access password.

    .PARAMETER RegRuLogin
        (DEPRECATED) Your Reg.Ru username.

    .PARAMETER RegRuPassword
        (DEPRECATED) Your Reg.Ru account or API access password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $cred

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [pscredential]$RegRuCredential,
        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 2)]
        [string]$RegRuLogin,
        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$RegRuPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $RegRuLogin = $RegRuCredential.UserName
        $RegRuPwdInsecure = $RegRuCredential.GetNetworkCredential().Password
    }

    try {
        Write-Verbose "Searching for existing TXT record"
        $zoneName, $recShort, $recExists = Get-RrTxtRecord $RecordName $TxtValue $RegRuLogin $RegRuPwdInsecure
    }
    catch { throw }

    if ($recExists) {
        # delete the record
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"

        $apiBase = 'https://api.reg.ru/api/regru2/zone/'

        $bodyParams = @{
            username            = $RegRuLogin
            password            = $RegRuPwdInsecure
            domains             = @( @{ dname = $zoneName } )
            subdomain           = $recShort
            text                = $TxtValue
            record_type         = 'TXT'
            output_content_type = 'plain'
        }
        $queryUri = '{0}remove_record?input_format=json&input_data={1}' -f $apiBase,(ConvertTo-RrBody $bodyParams)
        $bodyParams.password = 'XXXXXXXX'
        $querySanitized = '{0}remove_record?input_format=json&input_data={1}' -f $apiBase,(ConvertTo-RrBody $bodyParams)

        try {
            Write-Debug "GET $querySanitized"
            $response = Invoke-RestMethod $queryUri -EA Stop -Verbose:$false @script:UseBasic
            if ($response) { Write-Debug "Response:`n$(($response | ConvertTo-Json -Depth 10))" }
        }
        catch { throw }

        if ($response.result -ne 'success') {
            throw "Reg.ru API call failed removing record: $($response.error_text)"
        }

        $zoneObject = $($response.answer.domains | Where-Object { $_.dname -eq $zoneName })
        if ($zoneObject.result -ne 'success') {
            throw "$zoneName has error: $($zoneObject.error_text)"
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Reg.Ru.

    .DESCRIPTION
        Uses the Reg.Ru API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER RegRuCredential
        Your Reg.Ru username and either account password or API access password.

    .PARAMETER RegRuLogin
        (DEPRECATED) Your Reg.Ru username.

    .PARAMETER RegRuPassword
        (DEPRECATED) Your Reg.Ru account or API access password.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $cred

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

# API Docs
# https://www.reg.com/support/help/api2

function ConvertTo-RrBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$BodyInput
    )

    [uri]::EscapeDataString(($BodyInput | ConvertTo-Json -Compress -Depth 10))
}

function Get-RrTxtRecord {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RegRuLogin,
        [Parameter(Mandatory, Position = 3)]
        [string]$RegRuPwdInsecure
    )

    $apiBase = 'https://api.reg.ru/api/regru2/zone/'

    # The API supports the ability to request records for multiple zones in
    # a single query. So instead of the usual method where we make a request
    # per zone to find the zone and then request the records, we'll generate
    # all of our tests up front, request the records for all of them, and
    # use whichever one succeeds.

    $pieces = $RecordName.Split('.')
    $zoneTests = @(for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        @{ dname = ($pieces[$i..($pieces.Count-1)] -join '.') }
    })
    Write-Debug "Querying records for zones: $($zoneTests.dname -join ', ')"

    $bodyParams = @{
        username            = $RegRuLogin
        password            = $RegRuPwdInsecure
        domains             = $zoneTests
        output_content_type = 'plain'
    }
    $queryUri = '{0}get_resource_records?input_format=json&input_data={1}' -f $apiBase,(ConvertTo-RrBody $bodyParams)
    $bodyParams.password = 'XXXXXXXX'
    $querySanitized = '{0}get_resource_records?input_format=json&input_data={1}' -f $apiBase,(ConvertTo-RrBody $bodyParams)

    try {
        Write-Debug "GET $querySanitized"
        $response = Invoke-RestMethod $queryUri -EA Stop -Verbose:$false @script:UseBasic
        if ($response) { Write-Debug "Response:`n$(($response | ConvertTo-Json -Depth 10))" }
    }
    catch { throw }

    if ($response.result -ne 'success') {
        throw "Reg.ru API call failed querying zone records: $($response.error_text)"
    }

    # try to find a success among the domain results
    $zoneObject = $response.answer.domains |
        Where-Object { $_.result -eq 'success' } |
        Sort-Object -Descending { $_.dname.Length } |
        Select-Object -First 1

    # if we didn't find anything valid, write some verbose messages with the errors
    if (-not $zoneObject) {
        $response.answer.domains | Sort-Object -Descending { $_.dname.Length } | ForEach-Object {
            Write-Verbose "API Error: $($_.error_text)"
        }
        throw "Zone not found for $RecordName"
    }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneObject.dname), [string]::Empty).TrimEnd('.')
    if ($recShort -eq '') { $recShort = '@' }

    $rec = $zoneObject.rrs | Where-Object {
        $_.rectype -eq 'TXT' -and
        $_.subname -eq $recShort -and
        $_.content -eq $TxtValue
    }

    if ($rec) {
        return @($zoneObject.dname, $recShort, $true)
    } else {
        return @($zoneObject.dname, $recShort, $false)
    }

}
