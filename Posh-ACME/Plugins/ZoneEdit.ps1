function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$ZEUsername,
        [Parameter(Mandatory)]
        [pscredential[]]$ZEDynCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

    # get the cred that matches the record
    $dynCred = $ZEDynCredential | Where-Object {
        $RecordName -like "*$($_.UserName)"
    }
    if (-not $dynCred) {
        throw "ZEDynCredential did not contain any matches for $RecordName."
    }

    # create a new credential with the account username and zone specific password
    $cred = [pscredential]::new($ZEUsername,$dynCred.Password)

    $recHost = if ($dynCred.UserName -eq $RecordName) { "@.$RecordName" } else { $RecordName }

    # build the query
    $queryParams = @{
        Uri = 'https://dynamic.zoneedit.com/txt-create.php'
        Body = @{
            host = $recHost
            rdata = $TxtValue
        }
        Credential = $cred
        ErrorAction = 'Stop'
        Verbose = $false
    }

    try {
        Write-Debug "GET $($queryParams.Uri)`nhost = $recHost, rdata = $TxtValue"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch { throw }

    # The response from the API seems to be XML, but it's not actually valid enough
    # for PowerShell's parser to auto-parse it. So we'll just grab what we care about
    # via Regex. Examples:
    # <SUCCESS CODE="200" TEXT="_acme-challenge.example.com TXT updated to test value" ZONE="example.com">
    # <SUCCESS CODE="200" TEXT="_acme-challenge.example.com TXT with rdata test value deleted" ZONE="example.com">
    # <ERROR CODE="702" PARAM="10" TEXT="Minimum 10 seconds between requests" ZONE="_acme-challenge.example.com">
    # <ERROR CODE="702" PARAM="10" TEXT="zone LOCKED" ZONE="_acme-challenge.example.com">
    # <ERROR CODE="703" TEXT="No rdata specified" ZONE="">

    # 702 error codes seem to mean, try again in at least 10 seconds either because the last
    # call was too recent or the zone is locked after the last update.
    while ($response -notlike '<SUCCESS*') {
        Write-Debug ($response.Trim())
        $null = $response -match '\<(SUCCESS|ERROR) CODE="(?<code>\d+)".*TEXT="(?<msg>[^"]+)"'

        if ($matches.code -eq '702') {

            # try again in 10 seconds
            Write-Verbose "Retrying in 10 seconds: $($matches.msg)"
            Start-Sleep -Seconds 10

            try {
                Write-Debug "GET $($queryParams.Uri)`nhost = $recHost, rdata = $TxtValue"
                $response = Invoke-RestMethod @queryParams @script:UseBasic
            } catch { throw }
            continue

        } else {
            # any other errors we've seen are permanent and don't need to be tried again
            throw "API Error: $($matches.msg)"
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to ZoneEdit using their Dynamic TXT API.

    .DESCRIPTION
        Add a DNS TXT record to ZoneEdit using their Dynamic TXT API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZEUsername
        The username for your ZoneEdit account.

    .PARAMETER ZEDynCredential
        One or more PSCredential objects where the username is the zone name that
        contains the record you're updating and the password is the Dynamic Authentication
        Token configured for that zone.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -ZEUsername myuser -ZEDynCredential (Get-Credential)

        Adds a TXT record using the provided credentials.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$ZEUsername,
        [Parameter(Mandatory)]
        [pscredential[]]$ZEDynCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Write-Verbose "Removing a TXT record for $RecordName with value $TxtValue"

    # get the cred that matches the record
    $dynCred = $ZEDynCredential | Where-Object {
        $RecordName -like "*$($_.UserName)"
    }
    if (-not $dynCred) {
        throw "ZEDynCredential did not contain any matches for $RecordName."
    }

    # create a new credential with the account username and zone specific password
    $cred = [pscredential]::new($ZEUsername,$dynCred.Password)

    $recHost = if ($dynCred.UserName -eq $RecordName) { "@.$RecordName" } else { $RecordName }

    # build the query
    $queryParams = @{
        Uri = 'https://dynamic.zoneedit.com/txt-delete.php'
        Body = @{
            host = $recHost
            rdata = $TxtValue
        }
        Credential = $cred
        ErrorAction = 'Stop'
        Verbose = $false
    }

    try {
        Write-Debug "GET $($queryParams.Uri)`nhost = $recHost, rdata = $TxtValue"
        $response = Invoke-RestMethod @queryParams @script:UseBasic
    } catch { throw }

    # The response from the API seems to be XML, but it's not actually valid enough
    # for PowerShell's parser to auto-parse it. So we'll just grab what we care about
    # via Regex. Examples:
    # <SUCCESS CODE="200" TEXT="_acme-challenge.example.com TXT updated to test value" ZONE="example.com">
    # <SUCCESS CODE="200" TEXT="_acme-challenge.example.com TXT with rdata test value deleted" ZONE="example.com">
    # <ERROR CODE="702" PARAM="10" TEXT="Minimum 10 seconds between requests" ZONE="_acme-challenge.example.com">
    # <ERROR CODE="702" PARAM="10" TEXT="zone LOCKED" ZONE="_acme-challenge.example.com">
    # <ERROR CODE="703" TEXT="No rdata specified" ZONE="">

    # 702 error codes seem to mean, try again in at least 10 seconds either because the last
    # call was too recent or the zone is locked after the last update.
    while ($response -notlike '<SUCCESS*') {
        Write-Debug ($response.Trim())
        $null = $response -match '\<(SUCCESS|ERROR) CODE="(?<code>\d+)".*TEXT="(?<msg>[^"]+)"'

        if ($matches.code -eq '702') {

            # try again in 10 seconds
            Write-Verbose "Retrying in 10 seconds: $($matches.msg)"
            Start-Sleep -Seconds 10

            try {
                Write-Debug "GET $($queryParams.Uri)`nhost = $recHost, rdata = $TxtValue"
                $response = Invoke-RestMethod @queryParams @script:UseBasic
            } catch { throw }
            continue

        } else {
            # any other errors we've seen are permanent and don't need to be tried again
            throw "API Error: $($matches.msg)"
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to ZoneEdit using their Dynamic TXT API.

    .DESCRIPTION
        Add a DNS TXT record to ZoneEdit using their Dynamic TXT API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZEUsername
        The username for your ZoneEdit account.

    .PARAMETER ZEDynCredential
        One or more PSCredential objects where the username is the zone name that
        contains the record you're updating and the password is the Dynamic Authentication
        Token configured for that zone.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -ZEUsername myuser -ZEDynCredential (Get-Credential)

        Adds a TXT record using the provided credentials.
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
        Not required

    .DESCRIPTION
        This provider does not require calling this function to save DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
