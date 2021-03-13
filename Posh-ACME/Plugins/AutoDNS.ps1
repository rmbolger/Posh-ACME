function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$AutoDNSUser,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$AutoDNSPassword,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AutoDNSPasswordInsecure,
        [string]$AutoDNSContext='4',
        [string]$AutoDNSGateway='gateway.autodns.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # decrypt the securestring password so we can add it to the XML auth block
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $AutoDNSPasswordInsecure = (New-Object PSCredential "user",$AutoDNSPassword).GetNetworkCredential().Password
    }
    $authBlock = "<auth><user>$AutoDNSUser</user><password>$AutoDNSPasswordInsecure</password><context>$AutoDNSContext</context></auth>"
    $apiBase = "https://$AutoDNSGateway"

    try { $zoneName,$zoneNS = Find-AutoDNSZone $RecordName $authBlock $apiBase } catch { throw }
    Write-Debug "Found $zoneName with $zoneNS nameserver"

    # So the acme.sh plugin we're basing this one on just blindly adds the TXT
    # record to the zone now without checking to see if it already exists. During
    # testing, AutoDNS detects the duplicate record and just ignores it. So this is
    # probably fine.
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    $updateBody = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><request>$AuthBlock<task><code>0202001</code><default><rr_add><name>$recShort</name><ttl>600</ttl><type>TXT</type><value>$TxtValue</value></rr_add></default><zone><name>$zoneName</name><system_ns>$zoneNS</system_ns></zone></task></request>"
    try {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $result = (Invoke-RestMethod $apiBase -Method Post -Body $updateBody @script:UseBasic).response.result
        # check for errors
        if ($result.status.type -eq 'error') {
            throw "AutoDNS Error $($result.msg.code): $($result.msg.text)"
        } else {
            Write-Debug $result.OuterXml
        }
    } catch { throw }


    <#
    .SYNOPSIS
        Add a DNS TXT record to AutoDNS (or provider who uses AutoDNS's XML gateway)

    .DESCRIPTION
        Add a DNS TXT record to AutoDNS (or provider who uses AutoDNS's XML gateway)

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AutoDNSUser
        AutoDNS username.

    .PARAMETER AutoDNSPassword
        AutoDNS password. This SecureString version should only be used on Windows.

    .PARAMETER AutoDNSPasswordInsecure
        AutoDNS password. This standard String version should be used on non-Windows OSes.

    .PARAMETER AutoDNSContext
        ID of the personalized system of the subuser. Defaults to 4.

    .PARAMETER AutoDNSGateway
        Hostname of the AutoDNS Gateway. Defaults to gateway.autodns.com.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -AutoDnsUser 'user' -AutoDNSPasswordInsecure 'password'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$AutoDNSUser,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$AutoDNSPassword,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$AutoDNSPasswordInsecure,
        [string]$AutoDNSContext='4',
        [string]$AutoDNSGateway='gateway.autodns.com',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # decrypt the securestring password so we can add it to the XML auth block
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $AutoDNSPasswordInsecure = (New-Object PSCredential "user",$AutoDNSPassword).GetNetworkCredential().Password
    }
    $authBlock = "<auth><user>$AutoDNSUser</user><password>$AutoDNSPasswordInsecure</password><context>$AutoDNSContext</context></auth>"
    $apiBase = "https://$AutoDNSGateway"

    try { $zoneName,$zoneNS = Find-AutoDNSZone $RecordName $authBlock $apiBase } catch { throw }
    Write-Debug "Found $zoneName with $zoneNS nameserver"

    # So the acme.sh plugin we're basing this one on just blindly removes the TXT
    # record from the zone now without checking to see if it already exists. During
    # testing, it doesn't seem to care if you try and remove a record that's already
    # gone. So this is fine.
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    $updateBody = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><request>$AuthBlock<task><code>0202001</code><default><rr_rem><name>$recShort</name><ttl>600</ttl><type>TXT</type><value>$TxtValue</value></rr_rem></default><zone><name>$zoneName</name><system_ns>$zoneNS</system_ns></zone></task></request>"
    try {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        $result = (Invoke-RestMethod $apiBase -Method Post -Body $updateBody @script:UseBasic).response.result
        # check for errors
        if ($result.status.type -eq 'error') {
            throw "AutoDNS Error $($result.msg.code): $($result.msg.text)"
        } else {
            Write-Debug $result.OuterXml
        }
    } catch { throw }



    <#
    .SYNOPSIS
        Remove a DNS TXT record from AutoDNS (or provider who uses AutoDNS's XML gateway)

    .DESCRIPTION
        Remove a DNS TXT record from AutoDNS (or provider who uses AutoDNS's XML gateway)

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AutoDNSUser
        AutoDNS username.

    .PARAMETER AutoDNSPassword
        AutoDNS password. This SecureString version should only be used on Windows.

    .PARAMETER AutoDNSPasswordInsecure
        AutoDNS password. This standard String version should be used on non-Windows OSes.

    .PARAMETER AutoDNSContext
        ID of the personalized system of the subuser. Defaults to 4.

    .PARAMETER AutoDNSGateway
        Hostname of the AutoDNS Gateway. Defaults to gateway.autodns.com.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -AutoDnsUser 'user' -AutoDNSPasswordInsecure 'password'

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

# https://help.internetx.com/display/APIXMLEN/Welcome

function Find-AutoDNSZone {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$AuthBlock,
        [Parameter(Mandatory,Position=2)]
        [string]$Gateway
    )

    # setup a module variable to cache the record to zone/ns mapping
    # so it's quicker to find later
    if (!$script:AutoDNSRecordZones) { $script:AutoDNSRecordZones = @{} }

    # check for the record in the cache
    if ($script:AutoDNSRecordZones.ContainsKey($RecordName)) {
        return $script:AutoDNSRecordZones.$RecordName
    }

    $zoneInquireTemplate = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><request>$AuthBlock<task><code>0205</code><view><children>1</children><limit>1</limit></view><where><key>name</key><operator>eq</operator><value>{0}</value></where></task></request>"

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $zoneInquire = $zoneInquireTemplate -f $zoneTest
            $result = (Invoke-RestMethod $Gateway -Method Post -Body $zoneInquire @script:UseBasic).response.result

            # check for results
            if ($result.status.type -eq 'error') {
                throw "AutoDNS Error $($result.msg.code): $($result.msg.text)"
            } else {
                if ($result.data.summary -eq 1) {
                    $script:AutoDNSRecordZones.$RecordName = $result.data.zone.name,$result.data.zone.system_ns
                    return $result.data.zone.name,$result.data.zone.system_ns
                }
            }
        } catch { throw }
    }

    throw "No zone found for $RecordName"
}
