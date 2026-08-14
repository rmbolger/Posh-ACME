function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$GCKeyFile,
        [string[]]$GCProjectId,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Cloud DNS API Reference
    # https://cloud.google.com/dns/api/v1beta2/

    Connect-GCloudDns $GCKeyFile
    $GCProjectId = Split-GCProjectId $GCProjectId

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneID,$projID = Find-GCZone $RecordName $GCProjectId
    if (-not $zoneID -or -not $projID) {
        throw "Unable to find Google hosted zone for $RecordName in project(s) $($GCProjectId -join ',')"
    }

    $recRoot = "https://www.googleapis.com/dns/v1beta2/projects/$projID/managedZones/$zoneID"

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    # query the current txt record set
    $queryParams = @{
        Uri = '{0}/rrsets?type=TXT&name={1}.' -f $recRoot,$RecordName
        Headers = $script:GCToken.AuthHeader
        Verbose = $false
        Debug = $false
        ErrorAction = 'Stop'
    }
    try {
        Write-Debug "GET $($queryParams.Uri)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }
    $rrsets = $response.rrsets

    if ($rrsets.Count -eq 0) {
        # create a new record from scratch
        Write-Debug "Creating new record for $RecordName"
        $changeBody = @{
            additions = @(
                @{
                    name    = "$RecordName."
                    type    = 'TXT'
                    ttl     = 10
                    rrdatas = @($TxtValue)
                }
            )
        }
    } else {
        if ($TxtValue -in $rrsets[0].rrdatas) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
            return
        }

        # append to the existing value list which basically involves
        # both deleting and re-creating the record in the same "change"
        # operation
        Write-Debug "Appending to $RecordName with $($rrsets[0].Count) existing value(s)"
        $toDelete = $rrsets[0] | ConvertTo-Json | ConvertFrom-Json
        $rrsets[0].rrdatas += $TxtValue
        $changeBody = @{
            deletions = @($toDelete)
            additions = @($rrsets[0])
        }
    }

    Write-Verbose "Sending update for $RecordName"
    $queryParams = @{
        Uri         = "$recRoot/changes"
        Method      = 'Post'
        Body        = ($changeBody | ConvertTo-Json -Depth 5)
        Headers     = $script:GCToken.AuthHeader
        ContentType = 'application/json'
        Verbose     = $false
        Debug       = $false
        ErrorAction = 'Stop'
    }
    try {
        Write-Debug "POST $($queryParams.Uri)`n$($changeBody | ConvertTo-Json -Depth 5)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Google Cloud DNS.

    .DESCRIPTION
        Add a DNS TXT record to Google Cloud DNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GCKeyFile
        Path to a service account JSON file that contains the account's private key and other metadata. This should have been downloaded when originally creating the service account.

    .PARAMETER GCProjectId
        The Project ID (or IDs) that contain the DNS zones you will be modifying. This is only required if the GCKeyFile references an account in a different project than the DNS zone or you have zones in multiple projects. When using this parameter, include the project ID associated with the GCKeyFile in addition to any others you need.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -GCKeyFile .\account.json

        Adds a TXT record for the specified site with the specified value using the specified Google Cloud service account.
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
        [string]$GCKeyFile,
        [string[]]$GCProjectId,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Cloud DNS API Reference
    # https://cloud.google.com/dns/api/v1beta2/

    Connect-GCloudDns $GCKeyFile
    $GCProjectId = Split-GCProjectId $GCProjectId

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    $zoneID,$projID = Find-GCZone $RecordName $GCProjectId
    if (-not $zoneID -or -not $projID) {
        throw "Unable to find Google hosted zone for $RecordName in project(s) $($GCProjectId -join ',')"
    }

    $recRoot = "https://www.googleapis.com/dns/v1beta2/projects/$projID/managedZones/$zoneID"

    # Normalize the TxtValue to ensure it is wrapped in quotes
    if ($TxtValue -notmatch '^".*"$') {
        $TxtValue = "`"$TxtValue`""
    }

    # query the current txt record set
    $queryParams = @{
        Uri = '{0}/rrsets?type=TXT&name={1}.' -f $recRoot,$RecordName
        Headers = $script:GCToken.AuthHeader
        Verbose = $false
        Debug = $false
        ErrorAction = 'Stop'
    }
    try {
        Write-Debug "GET $($queryParams.Uri)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }
    $rrsets = $response.rrsets

    if ($rrsets.Count -eq 0) {
        Write-Debug "Record $RecordName already deleted."
        return
    } else {
        if ($TxtValue -notin $rrsets[0].rrdatas) {
            Write-Debug "Record $RecordName doesn't contain $TxtValue. Nothing to do."
            return
        }

        # removing the value involves deleting the existing record and
        # re-creating it without the value in the same change set. But if it's
        # the last one, we just want to delete it.
        Write-Debug "Removing from $RecordName with $($rrsets[0].Count) existing value(s)"
        $changeBody = @{
            deletions = @(
                ($rrsets[0] | ConvertTo-Json | ConvertFrom-Json)
            )
        }
        if ($rrsets[0].rrdatas.Count -gt 1) {
            $rrsets[0].rrdatas = @(
                $rrsets[0].rrdatas | Where-Object { $_ -ne $TxtValue }
            )
            $changeBody.additions = @($rrsets[0])
        }
    }

    Write-Verbose "Sending update for $RecordName"
    $queryParams = @{
        Uri         = "$recRoot/changes"
        Method      = 'Post'
        Body        = ($changeBody | ConvertTo-Json -Depth 5)
        Headers     = $script:GCToken.AuthHeader
        ContentType = 'application/json'
        Verbose     = $false
        Debug       = $false
        ErrorAction = 'Stop'
    }
    try {
        Write-Debug "POST $($queryParams.Uri)`n$($changeBody | ConvertTo-Json -Depth 5)"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Google Cloud DNS.

    .DESCRIPTION
        Remove a DNS TXT record from Google Cloud DNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GCKeyFile
        Path to a service account JSON file that contains the account's private key and other metadata. This should have been downloaded when originally creating the service account.

    .PARAMETER GCProjectId
        The Project ID (or IDs) that contain the DNS zones you will be modifying. This is only required if the GCKeyFile references an account in a different project than the DNS zone or you have zones in multiple projects. When using this parameter, include the project ID associated with the GCKeyFile in addition to any others you need.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -GCKeyFile .\account.json

        Removes a TXT record the specified site with the specified value using the specified Google Cloud service account.
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

function Connect-GCloudDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$GCKeyFile
    )

    # Using OAuth 2.0 for Server to Server Applications
    # https://developers.google.com/identity/protocols/OAuth2ServiceAccount

    # just return if we've already got a valid non-expired token
    if ($script:GCToken -and (Get-DateTimeOffsetNow) -lt $script:GCToken.Expires) {
        return
    }

    Write-Verbose "Signing into GCloud DNS"

    # We want to cache the contents of GCKeyFile so renewals don't break if the original
    # file is moved/deleted. But we still want to primarily use the actual file by default
    # in case it has been updated.

    # expand the path to the file
    $GCKeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($GCKeyFile)

    # get the previously cached values
    $cachedFiles = Import-PluginVar 'GCKeyObj'
    if (-not $cachedFiles -or $cachedFiles -is [string]) {
        $cachedFiles = [pscustomobject]@{}
    }

    if (Test-Path $GCKeyFile -PathType Leaf) {

        Write-Debug "Using key file"
        $GCKeyObj = Get-Content $GCKeyFile -Raw | ConvertFrom-Json

        # add the contents to our cached files
        $b64Contents = $GCKeyObj | ConvertTo-Json -Compress | ConvertTo-Base64Url
        $cachedFiles | Add-Member $GCKeyFile $b64Contents -Force
        Export-PluginVar 'GCKeyObj' $cachedFiles

    } elseif ($GCKeyFile -in $cachedFiles.PSObject.Properties.Name) {

        Write-Warning "GCKeyFile not found at `"$GCKeyFile`". Attempting to use cached key data."
        $b64Contents = $cachedFiles.$GCKeyFile
        try {
            $GCKeyObj = $b64Contents | ConvertFrom-Base64Url | ConvertFrom-Json
        } catch { throw }

    } else {
        throw "GCKeyFile not found at `"$GCKeyFile`" and no cached data exists."
    }

    Write-Debug "Loading private key for $($GCKeyObj.client_email)"
    $key = Import-Pem -InputString $GCKeyObj.private_key | ConvertFrom-BCKey

    $unixNow = (Get-DateTimeOffsetNow).ToUnixTimeSeconds()

    # build the claim set for DNS read/write
    $jwtClaim = @{
        iss   = $GCKeyObj.client_email
        aud   = $GCKeyObj.token_uri
        scope = 'https://www.googleapis.com/auth/ndev.clouddns.readwrite'
        exp   = ($unixNow + 3600).ToString()
        iat   = $unixNow.ToString()
    }
    Write-Debug "Claim set: $($jwtClaim | ConvertTo-Json)"

    # build a signed jwt
    $header = @{alg='RS256';typ='JWT'}
    $jwt = New-Jws $key $header ($jwtClaim | ConvertTo-Json -Compress) -Compact -NoHeaderValidation

    # build the POST body
    $authBody = "assertion=$jwt&grant_type=$([uri]::EscapeDataString('urn:ietf:params:oauth:grant-type:jwt-bearer'))"

    # attempt to sign in
    try {
        Write-Debug "Sending OAuth2 login"
        $response = Invoke-RestMethod $GCKeyObj.token_uri -Method Post -Body $authBody @script:UseBasic -Verbose:$false -Debug:$false
        Write-Debug ($response | ConvertTo-Json)
    } catch { throw }

    # save a custom token to memory
    $script:GCToken = @{
        AuthHeader = @{
            Authorization = "$($response.token_type) $($response.access_token)"
        }
        Expires = (Get-DateTimeOffsetNow).AddSeconds($response.expires_in - 300)
        DefaultProject = $GCKeyObj.project_id
    }

}

function Split-GCProjectId {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string[]]$GCProjectId
    )

    # Callers may supply the project list as a real array or as a single comma-
    # delimited string. Normalize both and fall back to the key file's project.
    $projIDs = @(
        $GCProjectId |
            ForEach-Object { $_.Split(',').Trim() } |
            Where-Object { $_ } |
            Select-Object -Unique
    )

    if ($projIDs.Count -eq 0) {
        $projIDs = @($script:GCToken.DefaultProject)
    }
    if ($projIDs.Count -eq 0 -or ($projIDs | Where-Object { [string]::IsNullOrWhiteSpace($_) })) {
        throw "No Google Cloud project ID available. Specify -GCProjectId or use a key file that contains a project_id."
    }

    Write-Debug "Using project(s): $($projIDs -join ',')"
    return $projIDs
}

function Find-GCZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string[]]$GCProjectId
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GCRecordZones) { $script:GCRecordZones = @{} }

    # check for the record in the cache
    if ($script:GCRecordZones.ContainsKey($RecordName)) {
        return $script:GCRecordZones.$RecordName
    }

    # Since Google could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    # remember projects we couldn't query at all so we only complain about each once
    # and can report them if the zone ends up not being found anywhere
    $projErrors = [ordered]@{}

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )."
        foreach ($projID in $GCProjectId) {

            # a project query that failed once will keep failing, so skip the rest
            if ($projErrors.Contains($projID)) { continue }

            Write-Debug "Checking '$zoneTest' in project '$projID'"

            # Query matching zones for this exact dnsName and choose a public match.
            $zone = $null
            $queryFailed = $false
            $uri = "https://www.googleapis.com/dns/v1beta2/projects/$projID/managedZones?dnsName=$([uri]::EscapeDataString($zoneTest))"
            $queryParams = @{
                Uri = $uri
                Headers = $script:GCToken.AuthHeader
                Verbose = $false
                Debug = $false
                ErrorAction = 'Stop'
            }
            Write-Debug "GET $uri"
            try {
                $response = Invoke-RestMethod @queryParams @script:UseBasic
                Write-Debug "$(Convertto-Json $response -Depth 5)"
            } catch {
                # One inaccessible project (no permission, Cloud DNS API not enabled,
                # wrong ID) shouldn't abort the search across the others.
                Write-Warning "Unable to query Google project '$projID': $($_.Exception.Message)"
                $projErrors[$projID] = $_.Exception.Message
                $queryFailed = $true
            }

            $zones = @($response.managedZones | Where-Object { $_ })
            $zone = $zones | Where-Object { $_.visibility -eq 'public' } | Select-Object -First 1

            if ($queryFailed) { continue }

            if ($zone) {
                Write-Debug "Found zone '$($zone.name)' ($($zone.id)) in project '$projID'"
                $script:GCRecordZones.$RecordName = @($zone.id,$projID)
                return $script:GCRecordZones.$RecordName
            }
            elseif ($zones.Count -gt 0) {
                Write-Warning "Found $($zones.Count) zone(s) matching '$zoneTest' in project '$projID' but none are public. Private zones are not supported for ACME validation."
            }
        }
    }

    if ($projErrors.Count -eq @($GCProjectId).Count) {
        throw "Unable to query any of the specified Google project(s). $(($projErrors.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ' | ')"
    }

    return $null
}
