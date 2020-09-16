function Add-DnsTxtGCloud {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$GCKeyFile,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Cloud DNS API Reference
    # https://cloud.google.com/dns/api/v1beta2/

    Connect-GCloudDns $GCKeyFile
    $token = $script:GCToken

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-GCZone $RecordName)) {
        throw "Unable to find Google hosted zone for $RecordName"
    }

    $recRoot = "https://www.googleapis.com/dns/v1beta2/projects/$($token.ProjectID)/managedZones/$zoneID"

    # query the current txt record set
    try {
        $response = Invoke-RestMethod "$recRoot/rrsets?type=TXT&name=$RecordName." `
            -Headers $script:GCToken.AuthHeader @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }
    $rrsets = $response.rrsets

    if ($rrsets.Count -eq 0) {
        # create a new record from scratch
        Write-Debug "Creating new record for $RecordName"
        $changeBody = @{additions=@(@{
            name="$RecordName.";
            type='TXT';
            ttl=10;
            rrdatas=@("`"$TxtValue`"")
        })}
    } else {
        if ("`"$TxtValue`"" -in $rrsets[0].rrdatas) {
            Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
            return
        }

        # append to the existing value list which basically involves
        # both deleting and re-creating the record in the same "change"
        # operation
        Write-Debug "Appending to $RecordName with $($rrsets[0].Count) existing value(s)"
        $toDelete = $rrsets[0] | ConvertTo-Json | ConvertFrom-Json
        $rrsets[0].rrdatas += "`"$TxtValue`""
        $changeBody = @{
            deletions=@($toDelete);
            additions=@($rrsets[0]);
        }
    }

    Write-Verbose "Sending update for $RecordName"
    Write-Debug ($changeBody | ConvertTo-Json -Depth 5)
    try {
        $response = Invoke-RestMethod "$recRoot/changes" -Method Post `
            -Body ($changeBody | ConvertTo-Json -Depth 5) `
            -Headers $script:GCToken.AuthHeader `
            -ContentType 'application/json' @script:UseBasic
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

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtGCloud '_acme-challenge.site1.example.com' 'asdfqwer12345678' -GCKeyFile .\account.json

        Adds a TXT record for the specified site with the specified value using the specified Google Cloud service account.
    #>
}

function Remove-DnsTxtGCloud {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$GCKeyFile,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Cloud DNS API Reference
    # https://cloud.google.com/dns/api/v1beta2/

    Connect-GCloudDns $GCKeyFile
    $token = $script:GCToken

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Find-GCZone $RecordName)) {
        throw "Unable to find Google hosted zone for $RecordName"
    }

    $recRoot = "https://www.googleapis.com/dns/v1beta2/projects/$($token.ProjectID)/managedZones/$zoneID"

    # query the current txt record set
    try {
        $response = Invoke-RestMethod "$recRoot/rrsets?type=TXT&name=$RecordName." `
            -Headers $script:GCToken.AuthHeader @script:UseBasic
        Write-Debug ($response | ConvertTo-Json -Depth 5)
    } catch { throw }
    $rrsets = $response.rrsets

    if ($rrsets.Count -eq 0) {
        Write-Debug "Record $RecordName already deleted."
        return
    } else {
        if ("`"$TxtValue`"" -notin $rrsets[0].rrdatas) {
            Write-Debug "Record $RecordName doesn't contain $TxtValue. Nothing to do."
            return
        }

        # removing the value involves deleting the existing record and
        # re-creating it without the value in the same change set. But if it's
        # the last one, we just want to delete it.
        Write-Debug "Removing from $RecordName with $($rrsets[0].Count) existing value(s)"
        $changeBody = @{
            deletions=@(($rrsets[0] | ConvertTo-Json | ConvertFrom-Json))
        }
        if ($rrsets[0].rrdatas.Count -gt 1) {
            $rrsets[0].rrdatas = @($rrsets[0].rrdatas | Where-Object { $_ -ne "`"$TxtValue`"" })
            $changeBody.additions = @($rrsets[0])
        }
    }

    Write-Verbose "Sending update for $RecordName"
    Write-Debug ($changeBody | ConvertTo-Json -Depth 5)
    try {
        $response = Invoke-RestMethod "$recRoot/changes" -Method Post `
            -Body ($changeBody | ConvertTo-Json -Depth 5) `
            -Headers $script:GCToken.AuthHeader `
            -ContentType 'application/json' @script:UseBasic
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

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtGCloud '_acme-challenge.site1.example.com' 'asdfqwer12345678' -GCKeyFile .\account.json

        Removes a TXT record the specified site with the specified value using the specified Google Cloud service account.
    #>
}

function Save-DnsTxtGCloud {
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

    # We want to save the contents of GCKeyFile so the user isn't necessarily stuck
    # keeping it wherever it originally was when they ran the command. But we still want
    # to use the file by default in case they've updated it as long as it still exists.

    $GCKeyFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($GCKeyFile)
    if (Test-Path $GCKeyFile -PathType Leaf) {
        Write-Debug "Using key file"
        $GCKeyObj = Get-Content $GCKeyFile | ConvertFrom-Json

        # export the contents as a plugin var
        $b64Contents = $GCKeyObj | ConvertTo-Json -Compress | ConvertTo-Base64Url
        Export-PluginVar GCKeyObj $b64Contents

    } else {
        $b64Contents = Import-PluginVar GCKeyObj

        if (-not $b64Contents) {
            throw "GCKeyFile not found at `"$GCKeyFile`" and no cached data exists."
        } else {
            Write-Warning "GCKeyFile not found at `"$GCKeyFile`". Attempting to use cached key data."
            try {
                $GCKeyObj = $b64Contents | ConvertFrom-Base64Url | ConvertFrom-Json
            } catch { throw }
        }
    }

    Write-Debug "Loading private key for $($GCKeyObj.client_email)"
    $key = Import-Pem -InputString $GCKeyObj.private_key | ConvertFrom-BCKey

    $unixNow = (Get-DateTimeOffsetNow).ToUnixTimeSeconds()

    # build the claim set for DNS read/write
    $jwtClaim = @{
        iss   = $GCKeyObj.client_email;
        aud   = $GCKeyObj.token_uri;
        scope = 'https://www.googleapis.com/auth/ndev.clouddns.readwrite';
        exp   = ($unixNow + 3600).ToString();
        iat   = $unixNow.ToString();
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
        $response = Invoke-RestMethod $GCKeyObj.token_uri -Method Post -Body $authBody @script:UseBasic
        Write-Debug ($response | ConvertTo-Json)
    } catch { throw }

    # save a custom token to memory
    $script:GCToken = @{
        AuthHeader = @{Authorization="$($response.token_type) $($response.access_token)"};
        Expires    = (Get-DateTimeOffsetNow).AddSeconds($response.expires_in - 300);
        ProjectID  = $GCKeyObj.project_id;
    }

}

function Find-GCZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:GCRecordZones) { $script:GCRecordZones = @{} }

    # check for the record in the cache
    if ($script:GCRecordZones.ContainsKey($RecordName)) {
        return $script:GCRecordZones.$RecordName
    }

    $token = $script:GCToken
    $projRoot = "https://www.googleapis.com/dns/v1beta2/projects/$($token.ProjectID)"

    # get the list of available zones
    try {
        $zones = (Invoke-RestMethod "$projRoot/managedZones" `
            -Headers $script:GCToken.AuthHeader @script:UseBasic).managedZones | Where-Object {$_.visibility -eq "public"}
    } catch { throw }

    # Since Google could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )."
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones.dnsName) {
            $zoneID = ($zones | Where-Object { $_.dnsName -eq $zoneTest }).id
            $script:GCRecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}
