function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$IBMCredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBMUser,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBMKey,
        [switch]$IBMPrivateNetwork,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the User/Key to a credential object if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secKey = ConvertTo-SecureString $IBMKey -AsPlainText -Force
        $IBMCredential = New-Object System.Management.Automation.PSCredential ($IBMUser, $secKey)
    }

    $apiBase = "https://api.softlayer.com/rest/v3"
    if ($IBMPrivateNetwork) {
        $apiBase = "https://api.service.softlayer.com/rest/v3"
    }

    # Find the zone ID/Name
    try { $zoneID,$zoneName = Find-IBMZone $RecordName $IBMCredential $apiBase } catch { throw }
    Write-Debug "Found zone $zoneName with ID $zoneID"

    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    # search for an existing record
    try { $rec = Get-IBMTxtRecord $zoneID $recShort $TxtValue $IBMCredential $apiBase } catch { throw }

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        try {
            Invoke-RestMethod "$apiBase/SoftLayer_Dns_Domain/$zoneID/createTxtRecord/$recShort/$TxtValue/60.json" `
                -Credential $IBMCredential @script:UseBasic | Out-Null
        } catch { throw }
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to IBM SoftLayer

    .DESCRIPTION
        Add a DNS TXT record to IBM SoftLayer

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IBMCredential
        The API User and Key for an IBM Cloud account with permissions to write TXT records on specified zones. This should only be used on Windows.

    .PARAMETER IBMUser
        The API User name for an IBM Cloud account with permissions to write TXT records on specified zones. This may be used on any OS.

    .PARAMETER IBMKey
        The API Key for an IBM Cloud account with permissions to write TXT records on specified zones. This may be used on any OS.

    .PARAMETER IBMPrivateNetwork
        If specified, the plugin will connect to the SoftLayer API over the private network. Use this only from a machine inside the IBM Cloud environment or from a machine with VPN access.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -IBMCredential $cred

        Adds a TXT record using a PSCredential object with the API User and Key. (Only works on Windows)

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -IBMUser 'SL00000' -IBMKey 'xxxxxxxxx'

        Adds a TXT record using standard strings for API User and Key. (Use this on non-Windows)
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$IBMCredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBMUser,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$IBMKey,
        [switch]$IBMPrivateNetwork,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the User/Key to a credential object if necessary
    if ('Insecure' -eq $PSCmdlet.ParameterSetName) {
        $secKey = ConvertTo-SecureString $IBMKey -AsPlainText -Force
        $IBMCredential = New-Object System.Management.Automation.PSCredential ($IBMUser, $secKey)
    }

    $apiBase = "https://api.softlayer.com/rest/v3"
    if ($IBMPrivateNetwork) {
        $apiBase = "https://api.service.softlayer.com/rest/v3"
    }

    # Find the zone ID/Name
    try { $zoneID,$zoneName = Find-IBMZone $RecordName $IBMCredential $apiBase } catch { throw }
    Write-Debug "Found zone $zoneName with ID $zoneID"

    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    # search for an existing record
    try { $rec = Get-IBMTxtRecord $zoneID $recShort $TxtValue $IBMCredential $apiBase } catch { throw }

    if ($rec) {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        try {
            Invoke-RestMethod "$apiBase/SoftLayer_Dns_Domain_ResourceRecord/$($rec.id)/deleteObject.json" `
                -Credential $IBMCredential @script:UseBasic | Out-Null
        } catch { throw }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."

    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from IBM SoftLayer

    .DESCRIPTION
        Remove a DNS TXT record from IBM SoftLayer

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IBMCredential
        The API User and Key for an IBM Cloud account with permissions to write TXT records on specified zones. This should only be used on Windows.

    .PARAMETER IBMUser
        The API User name for an IBM Cloud account with permissions to write TXT records on specified zones. This may be used on any OS.

    .PARAMETER IBMKey
        The API Key for an IBM Cloud account with permissions to write TXT records on specified zones. This may be used on any OS.

    .PARAMETER IBMPrivateNetwork
        If specified, the plugin will connect to the SoftLayer API over the private network. Use this only from a machine inside the IBM Cloud environment or from a machine with VPN access.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -IBMCredential $cred

        Removes a TXT record using a PSCredential object with the API User and Key. (Only works on Windows)

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -IBMUser 'SL00000' -IBMKey 'xxxxxxxxx'

        Removes a TXT record using standard strings for API User and Key. (Use this on non-Windows)
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
# https://softlayer.github.io/article/rest/
# https://softlayer.github.io/reference/datatypes/SoftLayer_Dns_Domain/

function Find-IBMZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$IBMCredential,
        [Parameter(Mandatory,Position=2)]
        [string]$ApiBase
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:IBMRecordZones) { $script:IBMRecordZones = @{} }

    # check for the record in the cache
    if ($script:IBMRecordZones.ContainsKey($RecordName)) {
        return $script:IBMRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $response = Invoke-RestMethod "$ApiBase/SoftLayer_Dns_Domain/getByDomainName/$zoneTest.json" `
                -Credential $IBMCredential @script:UseBasic

            # check for results
            if ($response) {
                $script:IBMRecordZones.$RecordName = $response[0].id,$response[0].name
                return $response[0].id,$response[0].name
            }
        } catch { throw }
    }

    throw "No zone found for $RecordName"
}

function Get-IBMTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ZoneID,
        [Parameter(Mandatory,Position=1)]
        [string]$HostShort,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=3)]
        [pscredential]$IBMCredential,
        [Parameter(Mandatory,Position=4)]
        [string]$ApiBase
    )

    # Build the wacky json-in-url object filter syntax that SoftLayer expects
    # https://softlayer.github.io/article/object-filters/
    $filter = @{ resourceRecords = @{
        host = @{ operation = $HostShort }
        type = @{ operation = 'txt' }
        data = @{ operation = $TxtValue }
    }} | ConvertTo-Json -Compress

    try {
        $rec = Invoke-RestMethod "$ApiBase/SoftLayer_Dns_Domain/$ZoneID/getResourceRecords.json?objectFilter=$filter" `
            -Credential $IBMCredential @script:UseBasic
        return $rec
    } catch { throw }
}
