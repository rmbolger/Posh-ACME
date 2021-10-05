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
        $zoneName, $rec = Get-RrDnsZone $RecordName $TxtValue $RegRuLogin $RegRuPwdInsecure
    }
    catch { throw }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    if ($rec) {
        Write-Verbose "Record $RecordName already contains $TxtValue. Nothing to do."
    }
    else {

        #Add new TXT record
        $url = 'https://api.reg.ru/api/regru2/zone/add_txt?input_format=json&input_data='
        $body = ConvertTo-RrBody @{
            "username"            = $RegRuLogin
            "password"            = $RegRuPwdInsecure
            "domains"             = @( @{"dname" = $zoneName} )
            "subdomain"           = $recShort
            "text"                = $TxtValue
            "output_content_type" = "plain"
        }

        $response = Invoke-RestMethod -Method GET -Uri $($url + $body) `
            -ContentType "application/json" -EA Stop @script:UseBasic

        if ($response.result -eq 'error') {
            throw $response.error_text
        }

        $selected = $($response.answer.domains | Where-Object { $_.dname -eq $zoneName })
        if ($selected.result -eq 'error') {
            throw $selected.error_text
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
        $zoneName, $rec = Get-RrDnsZone $RecordName $TxtValue $RegRuLogin $RegRuPwdInsecure
    }
    catch { throw }

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    if ($rec) {
        # delete the record
        Write-Verbose "Removing $RecordName with value $TxtValue"

        $url = 'https://api.reg.ru/api/regru2/zone/remove_record?input_format=json&input_data='
        $body = ConvertTo-RrBody @{
            "username"            = $RegRuLogin
            "password"            = $RegRuPwdInsecure
            "domains"             = @( @{"dname" = $zoneName} )
            "subdomain"           = $recShort
            "content"             = $TxtValue  # set content of existing record to prevent unwanted removal of other records with same type
            "record_type"         = "TXT"
            "output_content_type" = "plain"
        }

        $response = Invoke-RestMethod -Method GET -Uri $($url + $body) `
            -ContentType "application/json" -EA Stop @script:UseBasic
        if ($response.result -eq 'error') {
            throw $response.error_text
        }

        $selected = $($response.answer.domains | Where-Object { $_.dname -eq $zoneName })
        if ($selected.result -eq 'error') {
            throw $selected.error_text
        }
    }
    else {
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

    [uri]::EscapeDataString(($BodyInput | ConvertTo-Json -Compres -Depth 10))
}

function Get-RrDnsZone {
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


    $BaseApiUrl = 'https://api.reg.ru/api/regru2/zone/'

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:RRRecordZones) { $script:RRRecordZones = @{ } }

    # check for the record in the cache
    if ($script:RRRecordZones.ContainsKey($RecordName)) {
        $zone = $script:RRRecordZones.$RecordName
    }

    if (!$zone) {
        # find the zone for the closest/deepest sub-zone that would contain the record.
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {

            $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
            Write-Debug "Checking $zoneTest"
            $response = $null

            $body = ConvertTo-RrBody @{
                "username"            = $RegRuLogin
                "password"            = $RegRuPwdInsecure
                "domains"             = @( @{"dname" = $zoneTest} )
                "output_content_type" = "plain"
            }
            try {
                $response = Invoke-RestMethod -Method GET -Uri $($BaseApiUrl + 'nop?input_format=json&input_data=' + $body) `
                    -ContentType "application/json" -EA Stop @script:UseBasic
            }
            catch { throw }

            $Selected = $response.answer.domains | Where-Object { $_.dname -eq $zoneTest }

            if ($Selected.result -eq 'success') {
                $script:RRRecordZones.$RecordName = $zoneTest
                $zone = $zoneTest
                break
            }
            else {
                if ($response.result -ne 'success') {
                    Write-Debug "Failed to operate against Reg.Ru API. Check your login, password and allowed IPs."
                    throw $response.error_text
                }
                elseif ($Selected.error_code -notin 'DOMAIN_NOT_FOUND','INVALID_DOMAIN_NAME_FORMAT') {
                    throw "Reg.Ru API threw unexpected error: $($response.error_text)"
                }
                $response = $null
            }
        }
    }
    if ($zone) {
        # use the zone name we already found
        $body = ConvertTo-RrBody @{
            "username"            = $RegRuLogin
            "password"            = $RegRuPwdInsecure
            "domains"             = @( @{"dname" = $zone} )
            "output_content_type" = "plain"
        }
        $response = Invoke-RestMethod -Method GET -Uri $($BaseApiUrl + 'get_resource_records?input_format=json&input_data=' + $body) `
            -ContentType "application/json" -EA Stop @script:UseBasic

        if ($response.result -ne 'success') {
            "Failed to operate against Reg.Ru API. Check your login, password and allowed IPs." | Write-Host
            throw $response.error_text
        }

        $Selected = $response.answer.domains | Where-Object { $_.dname -eq $zone }
        if ($Selected.result -eq 'success') {
            $rec = $Selected.rrs | Where-Object { $_.content -eq $TxtValue }
        }
        else {
            throw $Selected.error_text
        }
    }
    else {
        throw "DNS zone not found"
    }
    return @($zone, $rec)
}
