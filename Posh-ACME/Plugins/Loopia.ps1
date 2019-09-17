function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$LoopiaUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$LoopiaPass,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$LoopiaPassInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the plaintext password if the secure version was used
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $LoopiaPassInsecure = (New-Object PSCredential "user",$LoopiaPass).GetNetworkCredential().Password
    }
    $creds = @($LoopiaUser,$LoopiaPassInsecure)

    $zoneName = Find-LoopiaZone $RecordName $creds
    if (-not $zoneName) {
        throw "No matching domain found for $RecordName"
    }
    Write-Debug "Found zone $zoneName"

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    if (-not (Test-LoopiaSubdomainExists $recShort $zoneName $creds)) {
        # we need to add the "subdomain" object before we add records to it
        Add-LoopiaSubdomain $recShort $zoneName $creds
    }

    $recID,$recCount = Test-LoopiaTXTRecordExists $recShort $zoneName $TxtValue $creds

    if ($recID) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Add-LoopiaTXTRecord $recShort $zoneName $TxtValue $creds
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to LoopiaDNS

    .DESCRIPTION
        Add a DNS TXT record to LoopiaDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LoopiaUser
        The Loopia API username.

    .PARAMETER LoopiaPass
        The Loopia API password. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER LoopiaPassInsecure
        The Loopia API password. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host -Prompt "Loopia API password" -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user@loopiaapi' $pass

        Adds the specified TXT record with the specified value using a secure password.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user@loopiaapi' 'pass-value'

        Adds the specified TXT record with the specified value using a plaintext password.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$LoopiaUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$LoopiaPass,
        [Parameter(ParameterSetName='Insecure',Mandatory,Position=3)]
        [string]$LoopiaPassInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the plaintext password if the secure version was used
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $LoopiaPassInsecure = (New-Object PSCredential "user",$LoopiaPass).GetNetworkCredential().Password
    }
    $creds = @($LoopiaUser,$LoopiaPassInsecure)

    $zoneName = Find-LoopiaZone $RecordName $creds
    if (-not $zoneName) {
        throw "No matching domain found for $RecordName"
    }
    Write-Debug "Found zone $zoneName"

    # separate the portion of the name that doesn't contain the zone name
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')

    if (-not (Test-LoopiaSubdomainExists $recShort $zoneName $creds)) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return
    }

    $recID,$recCount = Test-LoopiaTXTRecordExists $recShort $zoneName $TxtValue $creds

    if ($recID) {
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
        if ($recCount -gt 1) {
            # just remove the record
            Remove-LoopiaTXTRecord $recShort $zoneName $creds -RecordID $recID
        } else {
            # remove the whole subdomain
            Remove-LoopiaTXTRecord $recShort $zoneName $creds
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from LoopiaDNS

    .DESCRIPTION
        Remove a DNS TXT record from LoopiaDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER LoopiaUser
        The Loopia API username.

    .PARAMETER LoopiaPass
        The Loopia API password. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER LoopiaPassInsecure
        The Loopia API password. This standard String version may be used on any OS.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host -Prompt "Loopia API password" -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user@loopiaapi' $pass

        Removes the specified TXT record with the specified value using a secure password.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'user@loopiaapi' 'pass-value'

        Removes the specified TXT record with the specified value using a plaintext password.
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
# https://www.loopia.com/api/

# Loopia has this really weird concept of how DNS works. It calls all labels within a zone
# "subdomains". Records are one or more values within each subdomain. So two A records
# for www.example.com is basically two records within the www subdomain of the example.com
# domain. The web GUI for this is also pretty cuckoo pants.

function Format-LoopiaXmlBody {
    [CmdletBinding(DefaultParameterSetName='AddTxt')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$MethodName,
        [Parameter(Mandatory,Position=1)]
        [AllowEmptyString()]
        [string[]]$StringParams,
        [Parameter(ParameterSetName='AddTxt',Position=2)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='RemoveTxt',Position=2)]
        [int]$RecordID
    )

    # Loopia uses XMLRPC, but we're going to try and avoid using a full
    # fledged XMLRPC library for our simplistic needs. All calls we're using
    # only take a bunch of string parameters except for when we're adding a
    # TXT record which then needs a struct of the record details. So if the
    # $TxtValue is specified, we'll just assume we're adding it.

    # start the xml and method name
    $xml = "<?xml version=`"1.0`" encoding=`"UTF-8`"?><methodCall><methodName>$MethodName</methodName><params>"

    # add XML-escaped string params
    $StringParams | ForEach-Object {
        $xml += "<param><value><string>$([Security.SecurityElement]::Escape($_))</string></value></param>"
    }

    # add the record object if necessary
    if ($TxtValue) {
        $xml += "<param><struct><member><name>type</name><value><string>TXT</string></value></member><member><name>priority</name><value><int>0</int></value></member><member><name>ttl</name><value><int>300</int></value></member><member><name>rdata</name><value><string>$TxtValue</string></value></member></struct></param>"
    } elseif ($RecordID) {
        $xml += "<param><value><int>$RecordID</int></value></param>"
    }

    # close it up
    $xml += '</params></methodCall>'

    return $xml
}

function Find-LoopiaZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string[]]$UserPass
    )

    $apiBase = 'https://api.loopia.se/RPCSERV'

    if (!$script:LoopiaZones) { $script:LoopiaZones = @{} }

    if ($script:LoopiaZones.ContainsKey($RecordName)) {
        return $script:LoopiaZones.$RecordName
    }

    $body = Format-LoopiaXmlBody getDomains $UserPass
    try {
        $response = Invoke-RestMethod $apiBase -Method Post -Body $body @script:UseBasic -EA Stop -Verbose:$false
    } catch { throw }

    # the response should contain at least one member node unless there was an
    # error or this account has no domains
    $domains = $response.SelectNodes("//member[name='domain']/value/string").'#text'
    if (-not $domains) {
        # check for an error which is just in a returned parameter string
        $errText = $response.SelectNodes('//string').'#text'
        if (-not $errText) {
            return $null
        } else {
            throw "Error querying domain list: $errText"
        }
    }

    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zone = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zone"

        if ($zone -in $domains) {
            $script:LoopiaZones.$RecordName = $zone
            return $zone
        }
    }

    return $null

}

function Test-LoopiaSubdomainExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Subdomain,
        [Parameter(Mandatory,Position=1)]
        [string]$Domain,
        [Parameter(Mandatory,Position=2)]
        [string[]]$UserPass
    )

    $apiBase = 'https://api.loopia.se/RPCSERV'

    $body = Format-LoopiaXmlBody getSubdomains ($UserPass + @($Domain))
    try {
        Write-Debug "Checking for $Subdomain subdomain"
        $response = Invoke-RestMethod $apiBase -Method Post -Body $body @script:UseBasic -EA Stop -Verbose:$false
    } catch { throw }

    # The response here is just an array of string parameters which makes it
    # impossible to differentiate from an error response. So we'll just assume
    # people aren't creating sub-domains like 'AUTH_ERROR' or 'UNKNOWN_ERROR'
    $subdomains = $response.SelectNodes('//string').'#text'
    Write-Debug "Found subdomains: $($subdomains -join ', ')"

    if ($Subdomain -in $subdomains) {
        return $true
    } else {
        return $false
    }
}

function Add-LoopiaSubdomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Subdomain,
        [Parameter(Mandatory,Position=1)]
        [string]$Domain,
        [Parameter(Mandatory,Position=2)]
        [string[]]$UserPass
    )

    $apiBase = 'https://api.loopia.se/RPCSERV'

    $body = Format-LoopiaXmlBody addSubdomain ($UserPass + @($Domain,$Subdomain))
    try {
        Write-Debug "Adding $Subdomain subdomain"
        $response = Invoke-RestMethod $apiBase -Method Post -Body $body @script:UseBasic -EA Stop -Verbose:$false
    } catch { throw }

    $status = $response.SelectNodes('//string').'#text'
    if ('OK' -ne $status) {
        throw "Error adding Loopia subdomain $Subdomain to $($Domain): $status"
    }
}

function Test-LoopiaTXTRecordExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Subdomain,
        [Parameter(Mandatory,Position=1)]
        [string]$Domain,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=3)]
        [string[]]$UserPass
    )

    $apiBase = 'https://api.loopia.se/RPCSERV'

    $body = Format-LoopiaXmlBody getZoneRecords ($UserPass + @($Domain,$Subdomain))
    try {
        Write-Debug "Checking for TXT record with value $TxtValue"
        $response = Invoke-RestMethod $apiBase -Method Post -Body $body @script:UseBasic -EA Stop -Verbose:$false
    } catch { throw }

    $rec = $response.SelectSingleNode("//struct[member/value='$TxtValue' and member/value='TXT']")
    if ($rec) {
        # return the record_id value
        $recID = $rec.SelectSingleNode("//member[name='record_id']/value/int").'#text'
        $totalRecs = $rec.SelectNodes("//struct").Count
        return $recID,$totalRecs
    } else {
        # trying to determine the difference between an actual error and just no matches
        # or no records at all would be difficult. So we're just going to hope it doesn't
        # matter for the time being.
        return $null,0
    }
}

function Add-LoopiaTXTRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Subdomain,
        [Parameter(Mandatory,Position=1)]
        [string]$Domain,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=3)]
        [string[]]$UserPass
    )

    $apiBase = 'https://api.loopia.se/RPCSERV'

    $body = Format-LoopiaXmlBody addZoneRecord ($UserPass + @($Domain,$Subdomain)) $TxtValue
    try {
        Write-Debug "Adding TXT record for $Subdomain with value $TxtValue"
        $response = Invoke-RestMethod $apiBase -Method Post -Body $body @script:UseBasic -EA Stop -Verbose:$false
    } catch { throw }

    $status = $response.SelectNodes('//string').'#text'
    if ('OK' -ne $status) {
        throw "Error adding Loopia TXT record: $status"
    }
}

function Remove-LoopiaTXTRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Subdomain,
        [Parameter(Mandatory,Position=1)]
        [string]$Domain,
        [Parameter(Mandatory,Position=2)]
        [string[]]$UserPass,
        [Parameter(Position=3)]
        [int]$RecordID
    )

    $apiBase = 'https://api.loopia.se/RPCSERV'

    # If no RecordID was passed in, that means we're supposed to delete the
    # whole Subdomain presumably because it's empty or we'd be removing the
    # last record.

    if (-not $RecordID) {
        $body = Format-LoopiaXmlBody removeSubdomain ($UserPass + @($Domain,$Subdomain))
        Write-Debug "Removing $Subdomain from $Domain"
    } else {
        $body = Format-LoopiaXmlBody removeZoneRecord ($UserPass + @($Domain,$Subdomain)) -RecordID $RecordID
        Write-Debug "Removing record $RecordID from $Subdomain"
    }

    try {
        $response = Invoke-RestMethod $apiBase -Method Post -Body $body @script:UseBasic -EA Stop -Verbose:$false
    } catch { throw }

    $status = $response.SelectNodes('//string').'#text'
    if ('OK' -ne $status) {
        if (-not $RecordID) {
            throw "Error removing subdomain: $status"
        } else {
            throw "Error removing TXT record: $status"
        }
    }
}
