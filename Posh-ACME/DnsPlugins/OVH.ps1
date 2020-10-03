function Add-DnsTxtOVH {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$OVHAppKey,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHAppSecret,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHConsumerKey,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHAppSecretInsecure,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHConsumerKeyInsecure,
        [ValidateSet('ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca')]
        [string]$OVHRegion = 'ovh-eu',
        [switch]$OVHUseModify,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-OVH @PSBoundParameters

    $domain = Find-OVHDomain $RecordName
    $recShort = ($RecordName -ireplace [regex]::Escape($domain), [string]::Empty).TrimEnd('.')

    $recs = @(Get-OVHTxtRecords $recShort $domain)

    if ($recs | Where-Object { $_.target -eq "`"$TxtValue`"" }) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }
    elseif ($OVHUseModify) {

        Write-Debug "Checking for records to modify from the list: $(($recs.id -join ','))"

        # list the previously modified record IDs in the debug log
        if ($script:OVHModifiedRecs.Count -gt 0) {
            Write-Debug "Ignoring previously modified IDs: $(($script:OVHModifiedRecs -join ','))"
        }

        # try to modify an existing record we haven't already modified in this session
        $recsToModify = @($recs | Where-Object { $_.id -notin $script:OVHModifiedRecs })

        if ($recsToModify.Count -gt 0) {
            $modSuccess = $false

            foreach ($rec in $recsToModify) {
                $query = "$($script:OVHCreds.ApiBase)/domain/zone/$domain/record/$($rec.id)"
                $body = @{target="`"$TxtValue`""} | ConvertTo-Json -Compress
                try {
                    Write-Verbose "Attempting to modify record ID $($rec.id)."
                    Invoke-OVHRest PUT $query $body | Out-Null

                    # add the zone to be saved
                    if ($domain -notin $script:OVHZonesToSave) {
                        $script:OVHZonesToSave += $domain
                    }

                    $script:OVHModifiedRecs += $rec.id
                    $modSuccess = $true
                    break
                } catch {}
            }
            if (-not $modSuccess) {
                Write-Verbose "Failed to modify any existing records. Re-throwing the last exception."
                throw ($Error[0].Exception)
            }
        } else {
            throw "No existing records were found to modify in $domain that haven't already been modified."
        }
    }
    else {
        # add a new record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        $query = "$($script:OVHCreds.ApiBase)/domain/zone/$domain/record"
        $body = @{
            fieldType = 'TXT'
            subDomain = $recShort
            target    = "`"$TxtValue`""
        } | ConvertTo-Json -Compress

        Invoke-OVHRest POST $query $body | Out-Null

        # add the zone to be saved
        if ($domain -notin $script:OVHZonesToSave) {
            $script:OVHZonesToSave += $domain
        }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to OVH

    .DESCRIPTION
        Add a DNS TXT record to OVH

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER OVHAppKey
        The Application Key value associated with the OVH API application you created.

    .PARAMETER OVHAppSecret
        The SecureString version of the Application Secret value associated with the OVH API application you created.

    .PARAMETER OVHAppSecretInsecure
        The standard string version of the Application Secret value associated with the OVH API application you created.

    .PARAMETER OVHConsumerKey
        The SecureString version of the Consumer Key value generated for the API application you created.

    .PARAMETER OVHConsumerKeyInsecure
        The standard string version of the Consumer Key value generated for the API application you created.

    .PARAMETER OVHRegion
        The region code associated with your OVH account. Must be one of the following: 'ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca'

    .PARAMETER OVHUseModify
        If specified, the plugin will attempt to modify existing TXT records instead of adding/removing new ones. This is only necessary when the API credential has been given modify permissions on particular record IDs instead of write access to a whole zone.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $appSecret = Read-Host -Prompt "App Secret" -AsSecureString
        PS C:\>$cKey = Read-Host -Prompt "Consumer Key" -AsSecureString
        PS C:\>$pArgs = @{OVHAppKey='xxxxxxxx'; OVHAppSecret=$appSecret; OVHConsumerKey=$cKey; OVHRegion='ovh-eu'}
        PS C:\>Add-DnsTxtOVH '_acme-challenge.site1.example.com' 'asdfqwer12345678' @pArgs

        Adds a TXT record using SecureString parameter values.

    .EXAMPLE
        $pArgs = @{OVHAppKey='xxxxxxxx'; OVHAppSecret='yyyyyyyy'; OVHConsumerKey='zzzzzzzz'; OVHRegion='ovh-eu'}
        PS C:\>Add-DnsTxtOVH '_acme-challenge.site1.example.com' 'asdfqwer12345678' @pArgs

        Adds a TXT record using standard string parameter values.
    #>
}

function Remove-DnsTxtOVH {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$OVHAppKey,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHAppSecret,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHConsumerKey,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHAppSecretInsecure,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHConsumerKeyInsecure,
        [ValidateSet('ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca')]
        [string]$OVHRegion = 'ovh-eu',
        [switch]$OVHUseModify,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # if we're in modify mode, we don't do anything and leave the records as-is
    if ($OVHUseModify) {
        Write-Debug "Skipping record delete because Modify mode is enabled."
        return
    }

    Connect-OVH @PSBoundParameters

    $domain = Find-OVHDomain $RecordName
    $recShort = ($RecordName -ireplace [regex]::Escape($domain), [string]::Empty).TrimEnd('.')

    $recs = @(Get-OVHTxtRecords $recShort $domain)

    $rec = $recs | Where-Object { $_.target -eq "`"$TxtValue`"" }

    if ($rec) {
        # delete the record
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        $query = "$($script:OVHCreds.ApiBase)/domain/zone/$domain/record/$($rec.id)"
        Invoke-OVHRest DELETE $query | Out-Null

        # add the zone to be saved
        if ($domain -notin $script:OVHZonesToSave) {
            $script:OVHZonesToSave += $domain
        }
    }
    else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from OVH

    .DESCRIPTION
        Remove a DNS TXT record from OVH

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER OVHAppKey
        The Application Key value associated with the OVH API application you created.

    .PARAMETER OVHAppSecret
        The SecureString version of the Application Secret value associated with the OVH API application you created.

    .PARAMETER OVHAppSecretInsecure
        The standard string version of the Application Secret value associated with the OVH API application you created.

    .PARAMETER OVHConsumerKey
        The SecureString version of the Consumer Key value generated for the API application you created.

    .PARAMETER OVHConsumerKeyInsecure
        The standard string version of the Consumer Key value generated for the API application you created.

    .PARAMETER OVHRegion
        The region code associated with your OVH account. Must be one of the following: 'ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca'

    .PARAMETER OVHUseModify
        If specified, the plugin will attempt to modify existing TXT records instead of adding/removing new ones. This is only necessary when the API credential has been given modify permissions on particular record IDs instead of write access to a whole zone.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $appSecret = Read-Host -Prompt "App Secret" -AsSecureString
        PS C:\>$cKey = Read-Host -Prompt "Consumer Key" -AsSecureString
        PS C:\>$pArgs = @{OVHAppKey='xxxxxxxxxxx'; OVHAppSecret=$appSecret; OVHConsumerKey=$Key; OVHRegion='ovh-eu'}
        PS C:\>Remove-DnsTxtOVH '_acme-challenge.site1.example.com' 'asdfqwer12345678' @pArgs

        Removes a TXT record using SecureString parameter values.

    .EXAMPLE
        $pArgs = @{OVHAppKey='xxxxxxxx'; OVHAppSecret='yyyyyyyy'; OVHConsumerKey='zzzzzzzz'; OVHRegion='ovh-eu'}
        PS C:\>Remove-DnsTxtOVH '_acme-challenge.site1.example.com' 'asdfqwer12345678' @pArgs

        Removes a TXT record using standard string parameter values.
    #>
}

function Save-DnsTxtOVH {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory)]
        [string]$OVHAppKey,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHAppSecret,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHConsumerKey,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHAppSecretInsecure,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHConsumerKeyInsecure,
        [ValidateSet('ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca')]
        [string]$OVHRegion = 'ovh-eu',
        [switch]$OVHUseModify,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ($script:OVHCreds) {
        # Apply zone modifications by calling the "refresh" endpoint
        foreach ($zone in $script:OVHZonesToSave) {
            Write-Verbose "Refreshing $zone zone"
            Invoke-OVHRest POST "$($script:OVHCreds.ApiBase)/domain/zone/$zone/refresh" | Out-Null
        }
        $script:OVHZonesToSave = @()
    }

    $script:OVHModifiedRecs = @()

    <#
    .SYNOPSIS
        Notifies OVH to apply zone modifications.

    .DESCRIPTION
        Notifies OVH to apply zone modifications.

    .PARAMETER OVHAppKey
        The Application Key value associated with the OVH API application you created.

    .PARAMETER OVHAppSecret
        The SecureString version of the Application Secret value associated with the OVH API application you created.

    .PARAMETER OVHAppSecretInsecure
        The standard string version of the Application Secret value associated with the OVH API application you created.

    .PARAMETER OVHConsumerKey
        The SecureString version of the Consumer Key value generated for the API application you created.

    .PARAMETER OVHConsumerKeyInsecure
        The standard string version of the Consumer Key value generated for the API application you created.

    .PARAMETER OVHRegion
        The region code associated with your OVH account. Must be one of the following: 'ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca'

    .PARAMETER OVHUseModify
        If specified, the plugin will attempt to modify existing TXT records instead of adding/removing new ones. This is only necessary when the API credential has been given modify permissions on particular record IDs instead of write access to a whole zone.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# API Docs
# https://api.ovh.com/

function Connect-OVH {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory)]
        [string]$OVHAppKey,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHAppSecret,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$OVHConsumerKey,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHAppSecretInsecure,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$OVHConsumerKeyInsecure,
        [ValidateSet('ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca')]
        [string]$OVHRegion = 'ovh-eu',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # generate plain text versions of the secure params we can work with
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $OVHAppSecretInsecure = (New-Object PSCredential "user",$OVHAppSecret).GetNetworkCredential().Password
        $OVHConsumerKeyInsecure = (New-Object PSCredential "user",$OVHConsumerKey).GetNetworkCredential().Password
    }

    # determine the region specific API endpoint
    $apiBase = switch ($OVHRegion) {
        'ovh-eu'        { 'https://eu.api.ovh.com/1.0'; break }
        'ovh-us'        { 'https://api.us.ovhcloud.com/1.0'; break }
        'ovh-ca'        { 'https://ca.api.ovh.com/1.0'; break }
        'soyoustart-eu' { 'https://eu.api.soyoustart.com/1.0'; break }
        'soyoustart-ca' { 'https://ca.api.soyoustart.com/1.0'; break }
        'kimsufi-eu'    { 'https://eu.api.kimsufi.com/1.0'; break }
        'kimsufi-ca'    { 'https://ca.api.kimsufi.com/1.0'; break }
        'runabove-ca'   { 'https://api.runabove.com/1.0'; break }
        default { throw "Unknown OVHRegion: $OVHRegion" }
    }

    $script:OVHCreds = @{
        AppKey = $OVHAppKey
        AppSecret = $OVHAppSecretInsecure
        ConsumerKey = $OVHConsumerKeyInsecure
        ApiBase = $apiBase
    }

    # setup a tracking variable for zones we need to "refresh"
    if (-not $script:OVHZonesToSave) { $script:OVHZonesToSave = @() }

    # setup a tracking variable for modified records
    if (-not $script:OVHModifiedRecs) { $script:OVHModifiedRecs = @() }


}

function Invoke-OVHRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Method,
        [Parameter(Mandatory)]
        [string]$Url,
        [string]$Body
    )

    if (-not $script:OVHCreds) { throw "OVH Credentials not found in memory" }
    $c = $script:OVHCreds

    # build the string to hash for the signature
    # AppSecret '+' ConsumerKey '+' Method '+' Query '+' Body '+' Timestamp
    $unixNow = (Get-DateTimeOffsetNow).ToUnixTimeSeconds()
    $strToSign = "$($c.AppSecret)+$($c.ConsumerKey)+$($Method)+$($Url)+$($Body)+$($unixNow)"

    # hash it and make the signature
    # '$1$' + SHA1_HEX($strToHash)
    $sha1 = [Security.Cryptography.SHA1CryptoServiceProvider]::new()
    $strBytes = [Text.Encoding]::UTF8.GetBytes($strToSign)
    $hashHex = [BitConverter]::ToString($sha1.ComputeHash($strBytes)).Replace('-','').ToLower()
    $signature = "`$1`$$hashHex"

    $restArgs = @{
        Method = $Method
        Uri = $Url
        Headers = @{
            'X-Ovh-Application' = $c.AppKey
            'X-Ovh-Timestamp' = $unixNow
            'X-Ovh-Signature' = $signature
            'X-Ovh-Consumer' = $c.ConsumerKey
        }
        ContentType = 'application/json'
    }
    # add the body if there is one
    if ($Body) { $restArgs.Body = $Body }

    Invoke-RestMethod @restArgs @script:UseBasic -EA Stop
}

function Find-OVHDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:OVHRecordZones) { $script:OVHRecordZones = @{} }

    # check for the record in the cache
    if ($script:OVHRecordZones.ContainsKey($RecordName)) {
        return $script:OVHRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            # a non-error response indicates the zone exists
            Invoke-OvhRest GET "$($script:OVHCreds.ApiBase)/domain/zone/$zoneTest/record?fieldType=TXT" | Out-Null
            # save the zone name
            $script:OVHRecordZones.$RecordName = $zoneTest
            return $zoneTest
        } catch {
            # re-throw anything except a 403 or 404 because they indicate the zone
            # either doesn't exist or we haven't been given access to it.
            if (403 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Debug "$zoneTest either doesn't exist or our credentials haven't been given read access to it."
            }
            elseif (404 -eq $_.Exception.Response.StatusCode.value__) {
                Write-Debug "$zoneTest does not exist"
            }
            else { throw }
        }
    }

    throw "No zone found for $RecordName"
}

function Get-OVHTxtRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordShort,
        [Parameter(Mandatory)]
        [string]$Domain
    )

    # First we search for just the record and type which only returns a list of record IDs when found
    $query = "$($script:OVHCreds.ApiBase)/domain/zone/$Domain/record?fieldType=TXT&subDomain=$RecordShort"
    $recIDs = Invoke-OVHRest GET $query
    if (-not $recIDs) {
        return $null
    }

    # now we loop through the IDs to request the record details so we can check if the target matches
    foreach ($id in $recIDs) {
        Invoke-OVHRest GET "$($script:OVHCreds.ApiBase)/domain/zone/$Domain/record/$id"
    }
}

function Invoke-OVHSetup {
    [CmdletBinding(DefaultParameterSetName='AllOrList')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$AppKey,
        [ValidateSet('ovh-eu','ovh-us','ovh-ca','soyoustart-eu','soyoustart-ca','kimsufi-eu','kimsufi-ca','runabove-ca')]
        [string]$OVHRegion = 'ovh-eu',
        [Parameter(ParameterSetName='AllOrList')]
        [string[]]$Zone,
        [Parameter(ParameterSetName='Custom',Mandatory)]
        [object[]]$AccessRules
    )

    # So when creating an OVH app key, they don't give you the "Consumer Key" by default. They have
    # this funky OAuth'ish process where you have to login with the pre-created key/secret. The response
    # contains what will be your Consumer Key and a generated URL that the user must go to and explicitly
    # login and grant the permissions you've requested for a particular duration. Thankfully, unlimited
    # is an option.
    #
    # This is a helper function that the user must manually run once in order to generate the Consumer Key
    # value prior to the first certificate request.

    # determine the region specific API endpoint
    $apiBase = switch ($OVHRegion) {
        'ovh-eu'        { 'https://eu.api.ovh.com/1.0'; break }
        'ovh-us'        { 'https://api.us.ovhcloud.com/1.0'; break }
        'ovh-ca'        { 'https://ca.api.ovh.com/1.0'; break }
        'soyoustart-eu' { 'https://eu.api.soyoustart.com/1.0'; break }
        'soyoustart-ca' { 'https://ca.api.soyoustart.com/1.0'; break }
        'kimsufi-eu'    { 'https://eu.api.kimsufi.com/1.0'; break }
        'kimsufi-ca'    { 'https://ca.api.kimsufi.com/1.0'; break }
        'runabove-ca'   { 'https://api.runabove.com/1.0'; break }
        default { throw "Unknown OVHRegion: $OVHRegion" }
    }

    $header = @{ 'X-Ovh-Application' = $AppKey }

    # build the body that will request permissions for this app
    $body = @{
        redirection = 'https://github.com/rmbolger/Posh-ACME/wiki/OVH-Success-Redirect'
    }

    if ('AllOrList' -eq $PSCmdlet.ParameterSetName) {
        if ($Zone) {
            # setup permissions for a specific set of zones
            $body.accessRules = @()
            foreach ($z in $Zone) {
                $body.accessRules += @(
                    @{ method = 'GET';    path = "/domain/zone/$z/record*" }
                    @{ method = 'POST';   path = "/domain/zone/$z/record" }
                    @{ method = 'DELETE'; path = "/domain/zone/$z/record/*" }
                    @{ method = 'POST';   path = "/domain/zone/$z/refresh" }
                )
            }
        } else {
            # setup permissions for all zones
            $body.accessRules = @(
                @{ method = 'GET';    path = '/domain/zone/*/record*' }
                @{ method = 'POST';   path = '/domain/zone/*/record' }
                @{ method = 'DELETE'; path = '/domain/zone/*/record/*' }
                @{ method = 'POST';   path = '/domain/zone/*/refresh' }
            )
        }
    } else {
        # setup custom permissions
        $body.accessRules = $AccessRules
    }

    $bodyJson = $body | ConvertTo-Json -Compress

    $UseBasic = @{}
    if ('UseBasicParsing' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        $UseBasic.UseBasicParsing = $true
    }

    try {
        $response = Invoke-RestMethod "$($apiBase)/auth/credential" -Method Post -Body $bodyJson `
            -Headers $header -ContentType 'application/json' @UseBasic -EA Stop
    } catch { throw }

    if (-not $response -or -not $response.state) {
        throw "Empty auth response state"
    }
    if ($response.state -ne 'pendingValidation') {
        throw "Unexpected auth response: $(($response | ConvertTo-Json -Compress))"
    }

    Write-Host "`nPlease visit the following link, select Validity = `"Unlimited`", and then Log In:`n"
    Write-Host ($response.validationUrl)
    Read-Host "`nWhen finished, press Enter to continue" | Out-Null

    Write-Host "`n`nIf log in was successful, you may now use the following Consumer Key value in your plugin args:`n"
    Write-Host "   >>>   $($response.consumerKey)   <<<   "
}
