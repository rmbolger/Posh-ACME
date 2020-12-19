function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DomeneshopToken,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$DomeneshopSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$DomeneshopSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $Private:apiAuthorization = Get-DomeneshopAuthorization @PSBoundParameters } catch { throw }

    # find the zone for this record
    try { $oDomain = Find-DomeneshopZone -RecordName $RecordName -apiAuthorization $Private:apiAuthorization } catch { throw }
    Write-Debug ("Found zone {0} with id {1}" -f $oDomain.domain, $oDomain.id)

    $recShort = ($RecordName -ireplace [regex]::Escape($oDomain.domain), [string]::Empty).TrimEnd('.')

    # search for an existing record
    try { $rec = Get-DomeneshopTxtRecord -RecordShortName $recShort -TxtValue $TxtValue -ZoneID $oDomain.id -apiAuthorization $Private:apiAuthorization } catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $querystring = ("/{0}/dns" -f $oDomain.id)
        $bodyJson = @{ type="TXT"; host=$recShort; data=$TxtValue } | ConvertTo-Json

        Write-Verbose "Adding $RecordName with value $TxtValue"

        Invoke-DomeneshopAPI `
            -apiAuthorization $apiAuthorization `
            -QueryAdditions $querystring `
            -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Post) `
            -Body $bodyJson | Out-Null
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Domeneshop

    .DESCRIPTION
        Add a DNS TXT record to Domeneshop

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DomeneshopToken
        The API-token for the account logging in.

    .PARAMETER DomeneshopSecret
        The API-secret associated with your API-token. This SecureString version should only be used on Windows or PowerShell 6.2+.

    .PARAMETER DomeneshopSecretInsecure
        The API-secret associated with your API-token. This standard String version can be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' 'domen-token' (Read-Host "Secret" -AsSecureString)

        Adds a TXT record for the specified site with the specified value.
    #>
}


function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$DomeneshopToken,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$DomeneshopSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$DomeneshopSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get our auth body parameters
    try { $Private:apiAuthorization = Get-DomeneshopAuthorization @PSBoundParameters } catch { throw }

    # find the zone for this record
    try { $oDomain = Find-DomeneshopZone -RecordName $RecordName -apiAuthorization $Private:apiAuthorization } catch { throw }
    Write-Debug ("Found zone {0} with id {1}" -f $oDomain.domain, $oDomain.id)

    $recShort = ($RecordName -ireplace [regex]::Escape($oDomain.domain), [string]::Empty).TrimEnd('.')

    # search for an existing record
    try { $rec = Get-DomeneshopTxtRecord -RecordShortName $recShort -TxtValue $TxtValue -ZoneID $oDomain.id -apiAuthorization $Private:apiAuthorization } catch { throw }

    if ($rec) {
        Write-Verbose ("Removing TXT record id {2} for {0} with value {1}" -f $RecordName, $TxtValue, $rec.id)
        $querystring = ("/{0}/dns/{1}" -f $oDomain.id, $rec.id)

        Invoke-DomeneshopAPI `
            -apiAuthorization $apiAuthorization `
            -QueryAdditions $querystring `
            -Method ([Microsoft.PowerShell.Commands.WebRequestMethod]::Delete) | Out-Null
    } else {
        Write-Debug ("Record {0} with value {1} doesn't exist. Nothing to do." -f $RecordName, $TxtValue)
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Domeneshop

    .DESCRIPTION
        Remove a DNS TXT record from Domeneshop

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DomeneshopSecret
        The API-secret associated with your API-token. This SecureString version should only be used on Windows or PowerShell 6.2+.

    .PARAMETER DomeneshopSecretInsecure
        The API-secret associated with your API-token. This standard String version can be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txtvalue' 'domen-token' (Read-Host "Secret" -AsSecureString)

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
# https://github.com/domeneshop
# https://api.domeneshop.no/docs/


function Get-DomeneshopAuthorization {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DomeneshopToken,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=1)]
        [securestring]$DomeneshopSecret,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=1)]
        [string]$DomeneshopSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    try {
        # decrypt the secure password so we can add it to the querystring
        if ('Secure' -eq $PSCmdlet.ParameterSetName) {
            $Private:Credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $DomeneshopToken, $DomeneshopSecret
            $DomeneshopSecretInsecure = $Credential.GetNetworkCredential().Password
        }

        $Private:base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $DomeneshopToken, $DomeneshopSecretInsecure)))
        $Private:header = @{Authorization = ("Basic {0}" -f $Private:base64AuthInfo) }
        $Private:apiAuthorization =@{
            Headers = $Private:header
        }

        return $Private:apiAuthorization
    }
    catch { throw $_ }
	#region Unset cleartext password variables
    finally {
		Clear-Variable -Scope Private  `
				-Name "DomeneshopSecretInsecure" `
				-ErrorAction SilentlyContinue
    }
	#endregion
}

function Invoke-DomeneshopAPI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$apiAuthorization,
        [Parameter(Position=1)]
        [string]$QueryAdditions,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [string]$Body
    )

    $apiRoot = 'https://api.domeneshop.no/v0/domains'
    if ($QueryAdditions) { $apiRoot += $QueryAdditions }
    if ($Body) {
        $response = Invoke-RestMethod  `
            -Method $Method `
            -Uri $apiRoot `
            -Headers $apiAuthorization.Headers `
            -ContentType "application/json" `
            -Body $Body `
            @script:UseBasic `
            -ErrorAction Stop
    }
    else {
        $response = Invoke-RestMethod  `
            -Method $Method `
            -Uri $apiRoot `
            -Headers $apiAuthorization.Headers `
            -ContentType "application/json" `
            @script:UseBasic `
            -ErrorAction Stop    }

    return $response
}

function Find-DomeneshopZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$apiAuthorization
    )

    Write-Debug ("Find active DNS zone {0} at Domeneshop" -f $RecordName)
    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!(Get-Variable -Scope Script -Name 'DomeneshopRecordZones' -ErrorAction SilentlyContinue )) { $script:DomeneshopRecordZones = @{} }

    # check for the record in the cache
    if ($script:DomeneshopRecordZones.ContainsKey($RecordName)) {
        return $script:DomeneshopRecordZones.$RecordName
    }

    # Determine origin for zone
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug ("Checking {0}" -f $zoneTest)
        try {
            $querystring = ("?domain={0}" -f $zoneTest)
            $response = Invoke-DomeneshopAPI -apiAuthorization $apiAuthorization -QueryAdditions $querystring | `
                Where-Object -FilterScript { $_.Status -ieq 'active' -and $_.services.dns }

            # check for results
            if ($response) {
                Write-Debug ("Found active DNS zone {0} for {1} at Domeneshop" -f $response.domain, $RecordName)

                # Cache response
                $script:DomeneshopRecordZones.$RecordName = $response
                return $response
            }
        } catch { throw }
    }
    throw ("No active DNS zones found for {0} at Domeneshop" -f $RecordName)
}

function Get-DomeneshopTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordShortName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [int32]$ZoneID,
        [Parameter(Mandatory,Position=3)]
        [hashtable]$apiAuthorization
    )

    try {
        Write-Debug ("Fetching TXT records for {0} in zone id {1}" -f $RecordShortName, $ZoneID)

        $querystring = ("/{0}/dns" -f $ZoneID)
        $response = Invoke-DomeneshopAPI -apiAuthorization $apiAuthorization -QueryAdditions $querystring | `
            Where-Object -FilterScript { $_.type -ieq 'txt' -and $_.data -eq $TxtValue }

        if (!$response) { Write-Debug ("No TXT record {0} found in zone {1} at Domeneshop" -f $RecordShortName, $ZoneID) }
        else { Write-Debug ("Found TXT record {0} in zone id {1} at Domeneshop" -f $RecordShortName, $ZoneID) }

        return $response

    } catch { throw }
}
