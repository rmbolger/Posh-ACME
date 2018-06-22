function Add-DnsTxtGoDaddy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDKey,
        [Parameter(Mandatory, Position = 3)]
        [string]$GDSecret,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://api.godaddy.com/v1/domains"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v1/domains"
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    $zone = Find-GDZone -RecordName $RecordName -GDKey $GDKey -GDSecret $GDSecret
    $name = ($RecordName -split ".$zone")[0]
    
    $body = "[$(@{name= "$Name";type = 'TXT';ttl = 600; data = "$TxtValue"} | Convertto-Json)]"

    # Get a list of existing records
    try {
        $existingRecords = Invoke-RestMethod -Uri "$apiRoot/$zone/records" `
            -Method Get -Headers $headers @script:UseBasic
    }
    catch {
        throw "Unable to find zone $zone"
    }

    # Create the record if it doesn't exist or doesn't have the same value
    if (-not ($existingRecords | Where-Object {$_.type -eq "txt" -and $_.name -eq "$name" -and $_.data -eq "$TxtValue"})) {
        $response = Invoke-RestMethod -Uri "$apiRoot/$zone/records" `
            -Method Patch -Headers $headers -Body $body `
            -ContentType "application/json" @script:UseBasic

        Write-Debug ($response | ConvertTo-Json -Depth 5)
    }
    else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to GoDaddy.

    .DESCRIPTION
        Add a DNS TXT record to GoDaddy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDKey
        The GoDaddy API Key.

    .PARAMETER GDSecret
        The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtGoDaddy '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dfasdasf3j42f' 'adsfj834sadfda'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtGoDaddy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDKey,
        [Parameter(Mandatory, Position = 3)]
        [string]$GDSecret,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiRoot = "https://api.godaddy.com/v1/domains"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v1/domains"
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    $zone = Find-GDZone -RecordName $RecordName -GDKey $GDKey -GDSecret $GDSecret
    $name = ($RecordName -split ".$zone")[0]

    # Get a list of existing records
    try {
        $existingRecords = Invoke-RestMethod -Uri "$apiRoot/$zone/records" `
            -Method Get -Headers $headers @script:UseBasic
    }
    catch {
        throw
    }

    # Remove the txt record we want to delete
    $replaceRecords = $existingRecords `
        | Where-Object {-not ($_.type -eq "TXT" -and $_.name -eq "$name" -and $_.data -eq "$TxtValue")} `
        | ConvertTo-Json

    # Post the records we want to keep back to the API
    $response = Invoke-RestMethod -Uri "$apiRoot/$zone/records" `
        -Method Put -Headers $headers -Body $replaceRecords `
        -ContentType "application/json" @script:UseBasic

    Write-Debug ($response | ConvertTo-Json -Depth 5)

    <#
    .SYNOPSIS
        Remove a DNS TXT record from GoDaddy.

    .DESCRIPTION
        Remove a DNS TXT record from GoDaddy.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER GDKey
        The GoDaddy API Key.

    .PARAMETER GDSecret
        The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtGoDaddy '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dfasdasf3j42f' 'adsfj834sadfda'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtGoDaddy {
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

function Find-GDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$GDKey,
        [Parameter(Mandatory, Position = 2)]
        [string]$GDSecret,
        [Parameter(Mandatory = $false)]
        [switch]$GDUseOTE
    )

    $apiRoot = "https://api.godaddy.com/v1/domains"
    if ($GDUseOTE) {
        $apiRoot = "https://api.ote-godaddy.com/v1/domains"
    }

    $headers = @{Authorization = "sso-key $($GDKey):$($GDSecret)"}

    # get the list of available zones
    try {
        $zones = (Invoke-RestMethod -Uri $apiRoot -Headers $headers @script:UseBasic) `
            | Where-Object {$_.status -eq "ACTIVE"} `
            | Select-Object -ExpandProperty domain
    }
    catch { throw }

    # We need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i = 1; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones) {
            $zoneName = $zones | Where-Object { $_ -eq $zoneTest }
            return $zoneName
        }
    }

    return $null

    <#
    .SYNOPSIS
        Finds the appropriate DNS zone for the supplied record

    .DESCRIPTION
        Finds the appropriate DNS zone for the supplied record

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER GDKey
        The GoDaddy API Key.

    .PARAMETER GDSecret
        The GoDaddy API Secret.

    .PARAMETER GDUseOTE
        If specified, use the GoDaddy OTE test environment rather than the production environment.

    .EXAMPLE
        Find-GDZone -RecordName '_acme-challenge.site1.example.com' -GDKey 'asdfqwer12345678' -GDSecret 'dfasdasf3j42f'

        Finds the appropriate DNS zone for the supplied record
    #>
}
