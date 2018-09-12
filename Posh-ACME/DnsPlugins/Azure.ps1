function Add-DnsTxtAzure {
    [CmdletBinding(DefaultParameterSetName='Credential')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AZSubscriptionId,
        [Parameter(ParameterSetName='Credential',Mandatory,Position=3)]
        [string]$AZTenantId,
        [Parameter(ParameterSetName='Credential',Mandatory,Position=4)]
        [pscredential]$AZAppCred,
        [Parameter(ParameterSetName='Token',Mandatory,Position=3)]
        [string]$AZAccessToken,
        [Parameter(ParameterSetName='IMDS',Mandatory)]
        [switch]$AZUseIMDS,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-AZTenant @PSBoundParameters

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

    .PARAMETER AZAccessToken
        An existing Azure access token (JWT) to use for authorization when modifying TXT records. This is useful only for short lived instances or when the Azure authentication logic lives outside the module because access tokens are only valid for 1 hour.

    .PARAMETER AZUseIMDS
        If specified, the module will attempt to authenticate using the Azure Instance Metadata Service (IMDS). This will only work if the system is running within Azure and has been assigned a Managed Service Identity (MSI).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $azcred = Get-Credential
        PS C:\>Add-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZTenantId '22222222-2222-2222-2222-222222222222' -AZAppCred $azcred

        Adds a TXT record using expicit Azure tenant and credentials.

    .EXAMPLE
        $token = MyCustomLogin # external Azure auth
        PS C:\>Add-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZAccessToken $token

        Adds a TXT record using an existing Azure access token.

    .EXAMPLE
        Add-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZUseIMDS

        Adds a TXT record from within Azure using a token from Azure Instance Metadata Service.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermadserviceprincipal

    .LINK
        https://docs.microsoft.com/en-us/azure/dns/dns-protect-zones-recordsets

    .LINK
        https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview
    #>
}

function Remove-DnsTxtAzure {
    [CmdletBinding(DefaultParameterSetName='Credential')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$AZSubscriptionId,
        [Parameter(ParameterSetName='Credential',Mandatory,Position=3)]
        [string]$AZTenantId,
        [Parameter(ParameterSetName='Credential',Mandatory,Position=4)]
        [pscredential]$AZAppCred,
        [Parameter(ParameterSetName='Token',Mandatory,Position=3)]
        [string]$AZAccessToken,
        [Parameter(ParameterSetName='IMDS',Mandatory)]
        [switch]$AZUseIMDS,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-AZTenant @PSBoundParameters

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
                -Method Delete -Headers $script:AZToken.AuthHeader @script:UseBasic | Out-Null
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

    .PARAMETER AZAccessToken
        An existing Azure access token (JWT) to use for authorization when modifying TXT records. This is useful only for short lived instances or when the Azure authentication logic lives outside the module because access tokens are only valid for 1 hour.

    .PARAMETER AZUseIMDS
        If specified, the module will attempt to authenticate using the Azure Instance Metadata Service (IMDS). This will only work if the system is running within Azure and has been assigned a Managed Service Identity (MSI).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $azcred = Get-Credential
        PS C:\>Remove-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZTenantId '22222222-2222-2222-2222-222222222222' -AZAppCred $azcred

        Removes a TXT record for the specified site with the specified value.

    .EXAMPLE
        $token = MyCustomLogin # external Azure auth
        PS C:\>Remove-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZAccessToken $token

        Removes a TXT record using an existing Azure access token.

    .EXAMPLE
        Remove-DnsTxtAzure '_acme-challenge.site1.example.com' 'asdfqwer12345678' -AZSubscriptionId '11111111-1111-1111-1111-111111111111' -AZUseIMDS

        Removes a TXT record from within Azure using a token from Azure Instance Metadata Service.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermadserviceprincipal

    .LINK
        https://docs.microsoft.com/en-us/azure/dns/dns-protect-zones-recordsets

    .LINK
        https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/overview
    #>
}

function Save-DnsTxtAzure {
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

function ConvertFrom-AccessToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$AZAccessToken
    )

    # Anatomy of an access token
    # https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-token-and-claims

    # grab the payload section of the JWT
    $null,$payload,$null = $AZAccessToken.Split('.')

    # decode the claims
    $claims = $payload | ConvertFrom-Base64Url | ConvertFrom-Json -EA Stop

    # make sure the audience claim is correct
    if (-not $claims.aud -or $claims.aud -ne 'https://management.core.windows.net/') {
        throw "The provided access token has missing or incorrect audience claim. Expected: https://management.core.windows.net/"
    }

    # make sure the token hasn't expired
    $expires = [DateTimeOffset]::FromUnixTimeSeconds($claims.exp)
    if ((Get-DateTimeOffsetNow) -gt $expires) {
        throw "The provided access token has expired as of $($expires.ToString('u'))"
    }

    # return an object that contains the 'expires_on' property along with the token
    # which is what we care about from the other normal logon methods
    return [pscustomobject]@{
        expires_on = $claims.exp
        access_token = $AZAccessToken
    }
}

function Connect-AZTenant {
    [CmdletBinding(DefaultParameterSetName='Credential')]
    param(
        [Parameter(ParameterSetName='Credential',Mandatory,Position=0)]
        [string]$AZTenantId,
        [Parameter(ParameterSetName='Credential',Mandatory,Position=1)]
        [pscredential]$AZAppCred,
        [Parameter(ParameterSetName='Token',Mandatory,Position=0)]
        [string]$AZAccessToken,
        [Parameter(ParameterSetName='IMDS',Mandatory)]
        [switch]$AZUseIMDS,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # just return if we already have a valid Bearer token
    if ($script:AZToken ) {
        Write-Debug "Token Expires: $($script:AZToken.Expires)"
        if ((Get-DateTimeOffsetNow) -lt $script:AZToken.Expires) {
            Write-Debug "Existing token has not expired."
            return
        }
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Credential' {
            # login
            try {
                Write-Debug "Authenticating with explicit credentials"
                $authBody = "grant_type=client_credentials&client_id=$($AZAppCred.Username)&client_secret=$($AZAppCred.GetNetworkCredential().Password)&resource=$([uri]::EscapeDataString('https://management.core.windows.net/'))"
                $token = Invoke-RestMethod "https://login.microsoftonline.com/$($AZTenantId)/oauth2/token" `
                    -Method Post -Body $authBody @script:UseBasic
            } catch { throw }
            break
        }
        'Token' {
            # decode the token payload so we can get ultimately get its expiration
            Write-Debug "Authenticating with provided access token"
            $token = ConvertFrom-AccessToken $AZAccessToken
            break
        }
        'IMDS' {
            # If the module is running from an Azure resource utilizing Managed Service Identity (MSI),
            # we can get an access token via the Instance Metadata Service (IMDS):
            # https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/how-to-use-vm-token#get-a-token-using-azure-powershell
            try {
                Write-Debug "Authenticating with Instance Metadata Service (IMDS)"
                $queryString = "api-version=2018-02-01&resource=$([uri]::EscapeDataString('https://management.core.windows.net/'))"
                $token = Invoke-RestMethod "http://169.254.169.254/metadata/identity/oauth2/token?$queryString" `
                    -Headers @{Metadata='true'} @script:UseBasic
            } catch { throw }
            break
        }
    }

    Write-Debug "Retrieved token expiration: $token.expires_on"

    # create a token object that we can use for subsequence calls with a 5 min buffer on the expiration
    $script:AZToken = [pscustomobject]@{
        Expires    = [DateTimeOffset]::FromUnixTimeSeconds($token.expires_on).AddMinutes(-5)
        AuthHeader = @{ Authorization = "Bearer $($token.access_token)" }
    }
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
