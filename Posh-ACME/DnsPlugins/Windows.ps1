#Requires -Modules DnsServer, CimCmdlets

function Add-DnsTxtWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$WinServer,
        [Parameter(Position=3)]
        [pscredential]$WinCred,
        [switch]$WinUseSSL,
        [string]$WinZoneScope,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $cim = Connect-WinDns @PSBoundParameters
    Write-Verbose "Connected to $WinServer"

    $dnsParams = @{ ComputerName=$WinServer; CimSession=$cim }

    Write-Debug "Attempting to find zone for $RecordName"
    if (!($zoneName = Find-WinZone $RecordName $dnsParams)) {
        throw "Unable to find zone for $RecordName"
    }
    Write-Verbose "Found $zoneName"
    $zone = Get-DnsServerZone $zoneName @dnsParams -EA Stop

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    Write-Debug "Record short name: $recShort"

    # check for zone scope usage
    $zoneScope = @{}
    if (-not [String]::IsNullOrWhiteSpace($WinZoneScope)) {
        if ('ZoneScope' -notin (Get-Command Get-DnsServerResourceRecord).Parameters.Keys) {
            throw "ZoneScope is not supported in the version of the DnsServer module currently installed."
        } else {
            # In some configurations, not all zones that need to be modified have the specified
            # scope and will throw errors if you try to access them with a specified scope. So
            # we're going to make sure the specified scope exists before trying to use it.
            $scopes = $zone | Get-DnsServerZoneScope @dnsParams
            if ($WinZoneScope -in $scopes.ZoneScope) {
                $zoneScope.ZoneScope = $WinZoneScope
            }
        }
    }

    $recs = @($zone | Get-DnsServerResourceRecord -Name $recShort -RRType Txt @dnsParams @zoneScope -EA Ignore)

    if ($recs.Count -eq 0 -or $TxtValue -notin $recs.RecordData.DescriptiveText) {
        # create new
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $zone | Add-DnsServerResourceRecord -Txt -Name $recShort -DescriptiveText $TxtValue -TimeToLive 00:00:10 @dnsParams @zoneScope
    } else {
        # nothing to do
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to a Windows DNS server.

    .DESCRIPTION
        This plugin requires the "DnsServer" PowerShell module to be installed. On Windows Server OSes, you can install it with "Install-WindowsFeature RSAT-DNS-Server". On Windows client OSes, you will need to download and install the RSAT tools for your OS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER WinServer
        The hostname or IP address of the Windows DNS server.

    .PARAMETER WinCred
        Credentials with permissions to modify TXT records in the specified zone. This is optional if the current user has the proper permissions already.

    .PARAMETER WinUseSSL
        Forces the PowerShell remoting session to run over HTTPS. Requires the server have a valid certificate that is installed and trusted by the client or added to the client's TrustedHosts list. This is primarily used when connecting to a non-domain joined DNS server.

    .PARAMETER WinZoneScope
        The name of the zone scope to modify. This is generally only necessary in split-brain DNS configurations where the default scope is not external facing.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtWindows '_acme-challenge.site1.example.com' 'asdfqwer12345678' -WinServer 'dns1.example.com'

        Adds a TXT record using the credentials of the calling process.

    .EXAMPLE
        Add-DnsTxtWindows '_acme-challenge.site1.example.com' 'asdfqwer12345678' -WinServer 'dns1.example.com' -WinCred (Get-Credential) -WinUseSSL

        Adds a TXT record using explicit credentials and connecting over HTTPS.
    #>
}

function Remove-DnsTxtWindows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$WinServer,
        [Parameter(Position=3)]
        [pscredential]$WinCred,
        [switch]$WinUseSSL,
        [string]$WinZoneScope,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $cim = Connect-WinDns @PSBoundParameters
    Write-Verbose "Connected to $WinServer"

    $dnsParams = @{ ComputerName=$WinServer; CimSession=$cim }

    Write-Debug "Attempting to find zone for $RecordName"
    if (!($zoneName = Find-WinZone $RecordName $dnsParams)) {
        throw "Unable to find zone for $RecordName"
    }
    Write-Verbose "Found $zoneName"
    $zone = Get-DnsServerZone $zoneName @dnsParams -EA Stop

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    Write-Debug "Record short name: $recShort"

    # check for zone scope usage
    $zoneScope = @{}
    if (-not [String]::IsNullOrWhiteSpace($WinZoneScope)) {
        if ('ZoneScope' -notin (Get-Command Get-DnsServerResourceRecord).Parameters.Keys) {
            throw "ZoneScope is not supported in the version of the DnsServer module currently installed."
        } else {
            # In some configurations, not all zones that need to be modified have the specified
            # scope and will throw errors if you try to access them with a specified scope. So
            # we're going to make sure the specified scope exists before trying to use it.
            $scopes = $zone | Get-DnsServerZoneScope @dnsParams
            if ($WinZoneScope -in $scopes.ZoneScope) {
                $zoneScope.ZoneScope = $WinZoneScope
            }
        }
    }

    $recs = @($zone | Get-DnsServerResourceRecord -Name $recShort -RRType Txt @dnsParams @zoneScope -EA Ignore)

    if ($recs.Count -gt 0 -and $TxtValue -in $recs.RecordData.DescriptiveText) {
        # remove the record that has the right value
        $toDelete = $recs | Where-Object { $_.RecordData.DescriptiveText -eq $TxtValue }
        Write-Verbose "Deleting $RecordName with value $TxtValue"
        $zone | Remove-DnsServerResourceRecord -InputObject $toDelete -Force @dnsParams @zoneScope
    } else {
        # nothing to do
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from a Windows DNS server.

    .DESCRIPTION
        This plugin requires the "DnsServer" PowerShell module to be installed. On Windows Server OSes, you can install it with "Install-WindowsFeature RSAT-DNS-Server". On Windows client OSes, you will need to download and install the RSAT tools for your OS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER WinServer
        The hostname or IP address of the Windows DNS server.

    .PARAMETER WinCred
        Credentials with permissions to modify TXT records in the specified zone. This is optional if the current user has the proper permissions already.

    .PARAMETER WinUseSSL
        Forces the PowerShell remoting session to run over HTTPS. Requires the server have a valid certificate that is installed and trusted by the client or added to the client's TrustedHosts list. This is primarily used when connecting to a non-domain joined DNS server.

    .PARAMETER WinZoneScope
        The name of the zone scope to modify. This is generally only necessary in split-brain DNS configurations where the default scope is not external facing.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtWindows '_acme-challenge.site1.example.com' 'asdfqwer12345678' -WinServer 'dns1.example.com'

        Removes a TXT record using the credentials of the calling process.

    .EXAMPLE
        Remove-DnsTxtWindows '_acme-challenge.site1.example.com' 'asdfqwer12345678' -WinServer 'dns1.example.com' -WinCred (Get-Credential) -WinUseSSL

        Removes a TXT record using explicit credentials and connecting over HTTPS.
    #>
}

function Save-DnsTxtWindows {
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

function Connect-WinDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$WinServer,
        [Parameter(Position=1)]
        [pscredential]$WinCred,
        [switch]$WinUseSSL,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # create a new CimSession if necessary
    if (Get-CimSession -ComputerName $WinServer -EA Ignore) {
        Write-Debug "Using existing CimSession for $WinServer"
        return ((Get-CimSession -ComputerName $WinServer)[0])
    } else {
        Write-Debug "Connecting to $WinServer"
        $cimParams = @{ ComputerName=$WinServer }
        if ($WinCred) { $cimParams.Credential = $WinCred }
        if ($WinUseSSL) { $cimParams.SessionOption = (New-CimSessionOption -UseSsl) }
        return (New-CimSession @cimParams)
    }

}

function Find-WinZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$DnsParams
    )

    # setup a module variable to cache the record to zone mapping
    # so it's quicker to find later
    if (!$script:WinRecordZones) { $script:WinRecordZones = @{} }

    # check for the record in the cache
    if ($script:WinRecordZones.ContainsKey($RecordName)) {
        return $script:WinRecordZones.$RecordName
    }

    # get the zone list
    $zones = @(Get-DnsServerZone @DnsParams -EA Stop | Where-Object { !$_.IsAutoCreated -and $_.ZoneName -ne 'TrustAnchors' })

    # Since Windows could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"

        if ($zoneTest -in $zones.ZoneName) {
            $script:WinRecordZones.$RecordName = $zoneTest
            return $zoneTest
        }
    }

    return $null
}
