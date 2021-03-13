function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$DNSPodKeyId,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$DNSPodKeyToken,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$DNSPodKeyTokenInsecure,
        [Parameter(ParameterSetName='Secure')]
        [Parameter(ParameterSetName='Insecure')]
        [string]$DNSPodApiRoot='https://api.dnspod.com',
        [Parameter(ParameterSetName='Obsolete_DO_NOT_USE',Mandatory)]
        [pscredential]$DNSPodCredential,
        [Parameter(ParameterSetName='Obsolete_DO_NOT_USE',Mandatory)]
        [string]$DNSPodUsername,
        [Parameter(ParameterSetName='Obsolete_DO_NOT_USE',Mandatory)]
        [string]$DNSPodPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Obsolete_DO_NOT_USE' -eq $PSCmdlet.ParameterSetName) {
        throw "DNSPod requires updated API Key/Token values. See user guide for details."
    }

    # build the login_token value
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DNSPodKeyTokenInsecure = [pscredential]::new('a',$DNSPodKeyToken).GetNetworkCredential().Password
    }
    $authToken = "$DNSPodKeyId%2C$DNSPodKeyTokenInsecure"

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-DNSPodTxtRecord $RecordName $TxtValue $authToken $DNSPodApiRoot
    }
    catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }
    else {
        # add a new record
        try {
            Write-Verbose "Adding $RecordName with value $TxtValue"

            $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')
            $addQuery = @{
                Uri = "$DNSPodApiRoot/Record.Create"
                Method = 'POST'
                Body = "domain_id=$($zone.id)&sub_domain=$recShort&record_type=TXT&value=$TxtValue&record_line=%E9%BB%98%E8%AE%A4&login_token=$authToken&format=json&lang=en"
                UserAgent = $script:USER_AGENT
                ErrorAction = 'Stop'
            }
            #Write-Verbose ($addQuery.Body)
            $response = Invoke-RestMethod @addQuery @script:UseBasic

            if ($response.status.code -ne 1 -and $response.status.code -ne 31) {
                Write-Verbose ($response | ConvertTo-Json -dep 10)
                throw $response.status.message
            }
        }
        catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to DNSPod.

    .DESCRIPTION
        Uses the DNSPod DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSPodKeyId
        The API Key ID value.

    .PARAMETER DNSPodKeyToken
        The API Key Token value as a SecureString value. This should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DNSPodKeyTokenInsecure
        The API Key Token value as a standard String value.

    .PARAMETER DNSPodApiRoot
        The root URL for the DNSPod API you are using. Default to "https://api.dnspod.com" but may also be set to "https://dnsapi.cn".

    .PARAMETER DNSPodCredential
        Obsolete parameter that no longer works with DNSPod API. Do not use.

    .PARAMETER DNSPodUsername
        Obsolete parameter that no longer works with DNSPod API. Do not use.

    .PARAMETER DNSPodPwdInsecure
        Obsolete parameter that no longer works with DNSPod API. Do not use.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -DNSPodKeyId '1' -DnsPodKeyToken (Read-Host -AsSecureString)

        Adds a TXT record for the specified site with the specified value using a secure token value.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -DNSPodKeyId '1' -DnsPodKeyTokenInsecure 'token-value'

        Adds a TXT record for the specified site with the specified value using plain text token.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$DNSPodKeyId,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$DNSPodKeyToken,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$DNSPodKeyTokenInsecure,
        [Parameter(ParameterSetName='Secure')]
        [Parameter(ParameterSetName='Insecure')]
        [string]$DNSPodApiRoot='https://api.dnspod.com',
        [Parameter(ParameterSetName='Obsolete_DO_NOT_USE',Mandatory)]
        [pscredential]$DNSPodCredential,
        [Parameter(ParameterSetName='Obsolete_DO_NOT_USE',Mandatory)]
        [string]$DNSPodUsername,
        [Parameter(ParameterSetName='Obsolete_DO_NOT_USE',Mandatory)]
        [string]$DNSPodPwdInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Obsolete_DO_NOT_USE' -eq $PSCmdlet.ParameterSetName) {
        throw "DNSPod requires updated API Key/Token values. See user guide for details."
    }

    # build the login_token value
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $DNSPodKeyTokenInsecure = [pscredential]::new('a',$DNSPodKeyToken).GetNetworkCredential().Password
    }
    $authToken = "$DNSPodKeyId%2C$DNSPodKeyTokenInsecure"

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-DNSPodTxtRecord $RecordName $TxtValue $authToken $DNSPodApiRoot
    }
    catch { throw }

    if ($rec) {
        # delete the record
        try {
            Write-Verbose "Removing $RecordName with value $TxtValue"

            $delQuery = @{
                Uri = "$DNSPodApiRoot/Record.Remove"
                Method = 'POST'
                Body = "domain_id=$($zone.id)&record_id=$($rec.id)&login_token=$authToken&format=json&lang=en"
                UserAgent = $script:USER_AGENT
                ErrorAction = 'Stop'
            }
            $response = Invoke-RestMethod @delQuery @script:UseBasic

            if ($response.status.code -ne 1 -and $response.status.code -ne 8) {
                throw $response.status.message
            }
        }
        catch { throw }
    }
    else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from DNSPod.

    .DESCRIPTION
        Uses the DNSPod DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DNSPodKeyId
        The API Key ID value.

    .PARAMETER DNSPodKeyToken
        The API Key Token value as a SecureString value. This should only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DNSPodKeyTokenInsecure
        The API Key Token value as a standard String value.

    .PARAMETER DNSPodApiRoot
        The root URL for the DNSPod API you are using. Default to "https://api.dnspod.com" but may also be set to "https://dnsapi.cn".

    .PARAMETER DNSPodCredential
        Obsolete parameter that no longer works with DNSPod API. Do not use.

    .PARAMETER DNSPodUsername
        Obsolete parameter that no longer works with DNSPod API. Do not use.

    .PARAMETER DNSPodPwdInsecure
        Obsolete parameter that no longer works with DNSPod API. Do not use.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -DNSPodKeyId '1' -DnsPodKeyToken (Read-Host -AsSecureString)

        Removes a TXT record for the specified site with the specified value using a secure token value.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -DNSPodKeyId '1' -DnsPodKeyTokenInsecure 'token-value'

        Removes a TXT record for the specified site with the specified value using plain text token.
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
# https://docs.dnspod.cn/api

function Get-DNSPodTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$LoginToken,
        [Parameter(Mandatory,Position=3)]
        [string]$ApiRoot
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:DNSPodRecordZones) { $script:DNSPodRecordZones = @{ } }

    # check for the record in the cache
    if ($script:DNSPodRecordZones.ContainsKey($RecordName)) {
        $zone = $script:DNSPodRecordZones.$RecordName
    }

    if (-not $zone) {

        try {
            # get zone
            $zoneQuery = @{
                Uri = "$ApiRoot/Domain.List"
                Method = 'POST'
                Body = "login_token=$LoginToken&format=json&lang=en"
                UserAgent = $script:USER_AGENT
                ErrorAction = 'Stop'
            }
            $response = Invoke-RestMethod @zoneQuery @script:UseBasic

            if ($response.status.code -ne 1) {
                throw $response.status.message
            }
            else {
                [array]$hostedZones = $response.domains
            }

            $zone = $hostedZones | Where-Object { $RecordName -match $_.name }

            # save zone to cache
            $script:DNSPodRecordZones.$RecordName = $zone
        }
        catch { throw }

        if (-not $zone) {
            throw "Failed to find hosted zone for $RecordName"
        }

    }

    try {

        # separate the portion of the name that doesn't contain the zone name
        $recShort = ($RecordName -ireplace [regex]::Escape($zone.name), [string]::Empty).TrimEnd('.')

        # get record
        $recQuery = @{
            Uri = "$ApiRoot/Record.List"
            Method = 'POST'
            Body = "login_token=$LoginToken&format=json&lang=en&domain_id=$($zone.id)"
            UserAgent = $script:USER_AGENT
            ErrorAction = 'Stop'
        }
        $response = Invoke-RestMethod @recQuery @script:UseBasic

        if ($response.status.code -ne 1) {
            throw $response.status.message
        }
        else {
            $rec = $response.records | Where-Object {
                $_.name -eq $recShort -and
                $_.type -eq 'TXT' -and
                $_.value -eq $TxtValue
            }
        }
    }
    catch { throw }

    return @($zone, $rec)
}
