function Add-DnsTxtAzure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AZSubscriptionId,
        [Parameter(Mandatory,Position=3)]
        [string]$AZTenantId,
        [Parameter(Mandatory,Position=4)]
        [pscredential]$AZAppCred,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-AZTenant $AZTenantId $AZAppCred

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-AZZoneId $RecordName $AZSubscriptionId)) {
        throw "Unable to find Azure hosted zone for $RecordName"
    }

    # check for an existing record
    $rec = Get-AZTxtRecord $RecordName $zoneID

    # add (if necessary) the new TXT value to the list
    if ($rec.etag) {
        $txtVals = $rec.properties.TXTRecords
        if ($TxtValue -notin $txtVals.value) {
            $txtVals += @{value=@($TxtValue)}
        }
    } else {
        $txtVals = @(@{value=@($TxtValue)})
    }

    # build the record update json
    $recBody = @{properties=@{TTL=10;TXTRecords=$txtVals}} | ConvertTo-Json -Compress -Depth 5

    Write-Verbose "Sending updated $($rec.name)"
    Write-Debug $recBody
    try {
        $response = Invoke-RestMethod "https://management.azure.com$($rec.id)?api-version=2018-03-01-preview" `
            -Method Put -Body $recBody -Headers $script:AZToken.AuthHeader `
            -ContentType 'application/json' @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }


    <#
    .SYNOPSIS
        Add a DNS TXT record to an Azure hosted zone.

    .DESCRIPTION
        Use an App Registration service principal to add a TXT record to an Azure DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AZSubscriptionId
        The Subscription ID of the Azure DNS zone. This can be found on the Properties page of the zone.

    .PARAMETER AZTenantId
        The Tenant or Directory ID of the Azure AD instance that controls access to your Azure DNS zone. This can be found on the Properties page of your Azure AD instance.

    .PARAMETER AZAppCred
        The username and password for an Azure AD App Registration that has permissions to write TXT records on specified zone. The username is the Application ID of the App Registration which can be found on its Properties page. The password is whatever was set at creation time.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $azcred = Get-Credential
        PS C:\>Add-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZTenantId '22222222-2222-2222-2222-222222222222' -AZAppCred $azcred

        Adds a TXT record for the specified site with the specified value.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermadserviceprincipal

    .LINK
        https://docs.microsoft.com/en-us/azure/dns/dns-protect-zones-recordsets
    #>
}

function Remove-DnsTxtAzure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AZSubscriptionId,
        [Parameter(Mandatory,Position=3)]
        [string]$AZTenantId,
        [Parameter(Mandatory,Position=4)]
        [pscredential]$AZAppCred,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-AZTenant $AZTenantId $AZAppCred

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-AZZoneId $RecordName $AZSubscriptionId)) {
        throw "Unable to find Azure hosted zone for $RecordName"
    }

    # check for an existing record
    $rec = Get-AZTxtRecord $RecordName $zoneID

    # if the record has no etag, it means we faked it because it doesn't exist.
    # So just return
    if (!($rec.etag)) {
        Write-Verbose "Record $($rec.name) already removed."
        return
    }

    # remove the value if it exists
    $txtVals = $rec.properties.TXTRecords
    if ($TxtValue -notin $txtVals.value) {
        Write-Verbose "Record $($rec.name) doesn't contain $TxtValue. Nothing to do."
        return
    }
    $txtVals = @($txtVals | Where-Object { $_.value -ne $TxtValue })

    # delete the record if there are no values left
    if ($txtVals.Count -eq 0) {
        Write-Verbose "Deleting $($rec.name). No values left."
        try {
            Invoke-RestMethod "https://management.azure.com$($rec.id)?api-version=2018-03-01-preview" `
                -Method Delete -Headers $script:AZToken.AuthHeader  @script:UseBasic | Out-Null
            return
        } catch { throw }
    }

    # build the record update json
    $recBody = @{properties=@{TTL=10;TXTRecords=$txtVals}} | ConvertTo-Json -Compress -Depth 5

    Write-Verbose "Sending updated $($rec.name)"
    Write-Debug $recBody
    try {
        $response = Invoke-RestMethod "https://management.azure.com$($rec.id)?api-version=2018-03-01-preview" `
            -Method Put -Body $recBody -Headers $script:AZToken.AuthHeader `
            -ContentType 'application/json' @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from an Azure hosted zone.

    .DESCRIPTION
        Use an App Registration service principal to remove a TXT record from an Azure DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AZSubscriptionId
        The Subscription ID of the Azure DNS zone. This can be found on the Properties page of the zone.

    .PARAMETER AZTenantId
        The Tenant or Directory ID of the Azure AD instance that controls access to your Azure DNS zone. This can be found on the Properties page of your Azure AD instance.

    .PARAMETER AZAppCred
        The username and password for an Azure AD App Registration that has permissions to write TXT records on specified zone. The username is the Application ID of the App Registration which can be found on its Properties page. The password is whatever was set at creation time.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $azcred = Get-Credential
        PS C:\>Remove-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZTenantId '22222222-2222-2222-2222-222222222222' -AZAppCred $azcred

        Removes a TXT record for the specified site with the specified value.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermadserviceprincipal

    .LINK
        https://docs.microsoft.com/en-us/azure/dns/dns-protect-zones-recordsets
    #>
}

function Save-DnsTxtAzure {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. Azure doesn't require a save step

    <#
    .SYNOPSIS
        Not required for Azure.

    .DESCRIPTION
        Azure does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

function Connect-AZTenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$AZTenantId,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$AZAppCred
    )

    # just return if we already have a valid Bearer token
    if ($script:AZToken -and (Get-Date) -lt $script:AZToken.Expires) {
        return
    }

    # build the oAuth2 body
    $authBody = "grant_type=client_credentials&client_id=$($AZAppCred.Username)&client_secret=$($AZAppCred.GetNetworkCredential().Password)&resource=$([uri]::EscapeDataString('https://management.core.windows.net/'))"

    # login
    try {
        $token = Invoke-RestMethod "https://login.microsoftonline.com/$($AZTenantId)/oauth2/token" `
            -Method Post -Body $authBody @script:UseBasic
    } catch { throw }

    # add an "Expires" [datetime] parameter converted from expires_on with a 5 min buffer
    $token | Add-Member -MemberType NoteProperty -Name 'Expires' -Value ([datetime]'1/1/1970').AddSeconds($token.expires_on-300)

    $script:AZToken = $token | Select-Object `
        @{L='Expires';E={([datetime]'1/1/1970').AddSeconds($_.expires_on-300)}}, `
        @{L='AuthHeader';E={@{Authorization="Bearer $($_.access_token)"}}}
}

function Get-AZZoneId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$AZSubscriptionId
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:AZRecordZones) { $script:AZRecordZones = @{} }

    # check for the record in the cache
    if ($script:AZRecordZones.ContainsKey($RecordName)) {
        return $script:AZRecordZones.$RecordName
    }

    # get the list of available zones
    # https://docs.microsoft.com/en-us/rest/api/dns/zones/list
    $url = "https://management.azure.com/subscriptions/$($AZSubscriptionId)/providers/Microsoft.Network/dnszones?api-version=2018-03-01-preview"
    try {
        $zones = Invoke-RestMethod $url -Headers $script:AZToken.AuthHeader @script:UseBasic
    } catch { throw }

    # Since Azure could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    Write-Verbose "Found zones: $($zones.value.name -join ', ')"

    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Verbose "Checking $zoneTest"

        if ($zoneTest -in $zones.value.name) {
            $zoneID = ($zones.value | Where-Object { $_.name -eq $zoneTest }).id
            $script:AZRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}

function Get-AZTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$ZoneId
    )

    # parse the zone name from the zone id and strip it from $RecordName
    # to get the relativeRecordSetName
    $zoneName = $ZoneID.Substring($ZoneID.LastIndexOf('/')+1)
    $relName = $RecordName.Replace(".$zoneName",'')
    $recID = "$ZoneID/TXT/$($relName)"

    # query the specific record we're looking to modify
    Write-Verbose "Querying $RecordName"
    try {
        $rec = Invoke-RestMethod "https://management.azure.com$($recID)?api-version=2018-03-01-preview" `
            -Headers $script:AZToken.AuthHeader @script:UseBasic
    } catch {}

    if ($rec) {
        return $rec
    } else {
        # build a fake (no etag) empty record to send back
        $rec = @{id=$recID; name=$relName; properties=@{fqdn="$RecordName."; TXTRecords=@()}}
        return $rec
    }
}
