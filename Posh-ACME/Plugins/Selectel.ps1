function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 2)]
        [securestring]$SelectelAdminToken,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$SelectelAdminTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext token if the secure version was used
    # and make the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SelectelAdminTokenInsecure = (New-Object PSCredential "user", $SelectelAdminToken).GetNetworkCredential().Password
    }
    $AuthHeader = @{ 'X-Token' = $SelectelAdminTokenInsecure }

    $apiRoot = 'https://api.selectel.ru/domains/v1/'

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-SelectelTxtRecord $RecordName $TxtValue $AuthHeader
    }
    catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }
    else {
        # add a new record
        $body = @{
            'name'    = $RecordName
            'type'    = "TXT"
            'ttl'     = "60"
            'content' = $TxtValue
        } | ConvertTo-Json
        try {
            Write-Verbose "Adding $RecordName with value $TxtValue"
            $rec = Invoke-RestMethod -Method POST -Uri $($apiRoot + $zone.id.ToString() + '/records/') `
                -Headers $AuthHeader -ContentType 'application/json' -Body $body `
                -EA Stop @script:UseBasic
        }
        catch { throw }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Selectel.

    .DESCRIPTION
        Uses the Selectel DNS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SelectelAdminToken
        The Selectel admin token generated for your account. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER SelectelAdminTokenInsecure
        The Selectel admin token generated for your account. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "Selectel Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token

        Adds the specified TXT record with the specified value using a secure token.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'my-token'

        Adds the specified TXT record with the specified value using a plaintext token.
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
        [securestring]$SelectelAdminToken,
        [Parameter(ParameterSetName = 'Insecure', Mandatory, Position = 2)]
        [string]$SelectelAdminTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext token if the secure version was used
    # and make the auth header
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $SelectelAdminTokenInsecure = (New-Object PSCredential "user", $SelectelAdminToken).GetNetworkCredential().Password
    }
    $AuthHeader = @{ 'X-Token' = $SelectelAdminTokenInsecure }

    $apiRoot = 'https://api.selectel.ru/domains/v1/'

    try {
        Write-Verbose "Searching for existing TXT record"
        $zone, $rec = Get-SelectelTxtRecord $RecordName $TxtValue $AuthHeader
    }
    catch { throw }

    if ($rec) {
        # delete the record
        try {
            Write-Verbose "Removing $RecordName with value $TxtValue"
            Invoke-RestMethod -Method DELETE -Uri ($apiRoot + $zone.id.ToString() + '/records/' + $rec.id) `
                -Headers $AuthHeader -ContentType 'application/json' -EA Stop @script:UseBasic | Out-Null
        }
        catch { throw }
    }
    else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Selectel.

    .DESCRIPTION
        Uses the Selectel DNS API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SelectelAdminToken
        The Selectel admin token generated for your account. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER SelectelAdminTokenInsecure
        The Selectel admin token generated for your account. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host -Prompt "Selectel Token" -AsSecureString
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
# https://kb.selectel.com/docs/cloud-services/dns-hosting/api/dns_api/

function Get-SelectelTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [hashtable]$AuthHeader
    )

    $apiRoot = 'https://api.selectel.ru/domains/v1/'

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:SelectelRecordZones) { $script:SelectelRecordZones = @{ } }

    # check for the record in the cache
    if ($script:SelectelRecordZones.ContainsKey($RecordName)) {
        $zone = $script:SelectelRecordZones.$RecordName
    }

    if (!$zone) {

        try {
            # get zone
            [array]$hostedZones = Invoke-RestMethod -Method GET -Uri $apiRoot -Headers $AuthHeader `
                -ContentType 'application/json' -EA Stop @script:UseBasic
            $zone = $hostedZones | Where-Object { $RecordName -match $_.name }
            Remove-Variable hostedZones

            #save zone to cache
            $script:SelectelRecordZones.$RecordName = $zone
        }
        catch { throw }
    }
    if (!$zone) {
        throw "Failed to find hosted zone for $RecordName"
    }

    try {
        # get record
        [array]$records = Invoke-RestMethod -Method GET -Uri ($apiRoot + $zone.id.ToString() + '/records/') `
            -Headers $AuthHeader -ContentType 'application/json' -EA Stop @script:UseBasic
        $rec = $records | Where-Object { $_.name -eq $RecordName -and $_.type -eq 'TXT' -and $_.content -eq $TxtValue }
        Remove-Variable records
    }
    catch { throw }

    return @($zone, $rec)
}
