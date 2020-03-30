function Add-DnsTxtRFC2136 {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$DDNSNameserver,
        [string]$DDNSPort=53,
        [string]$DDNSKeyName,
        [ValidateSet('hmac-md5','hmac-sha1','hmac-sha224','hmac-sha256','hmac-sha384','hmac-sha512')]
        [string]$DDNSKeyType,
        [Parameter(ParameterSetName='Secure')]
        [securestring]$DDNSKeyValue,
        [Parameter(ParameterSetName='Insecure')]
        [string]$DDNSKeyValueInsecure,
        [string]$DDNSExePath='nsupdate',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext key value if it was specified
    if ($DDNSKeyValue -and 'Secure' -eq $PSCmdlet.ParameterSetName) {
        $DDNSKeyValueInsecure = (New-Object PSCredential "user",$DDNSKeyValue).GetNetworkCredential().Password
    }

    $zoneName = Find-DDNSRootDomain $RecordName $DDNSNameserver
    if (-not $zoneName) {
        throw "Unable to find authoritative domain for $RecordName on $DDNSNameserver"
    }
    Write-Verbose "Found authoritative zone $zoneName"

    # The nice thing about RFC2136 is that BIND doesn't care if you send duplicate updates
    # for the same record and value. So we don't need to check whether the record already
    # exists or not. Even if you're removing a record that's already gone, it still works.

    # build the params we'll send to the update function
    $updateParams = @{
        RecordName = "$RecordName."
        TxtValue = $TxtValue
        Action = 'add'
        Zone = "$zoneName."
        Nameserver = $DDNSNameserver
        Port = $DDNSPort
        NSUpdatePath = $DDNSExePath
    }

    # add the TSIG params if they were included
    if ($DDNSKeyName -and $DDNSKeyType -and $DDNSKeyValueInsecure) {
        $updateParams.TsigKeyName = $DDNSKeyName
        $updateParams.TsigKeyType = $DDNSKeyType
        $updateParams.TsigKeyValue = $DDNSKeyValueInsecure
    }

    Write-Verbose "Adding $RecordName with value $TxtValue"
    Send-DynamicTXTUpdate @updateParams


    <#
    .SYNOPSIS
        Add a DNS TXT record using RFC2136

    .DESCRIPTION
        Uses the nsupdate utility to send dynamic updates to an authoritative nameserver.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DDNSNameserver
        The hostname or IP address of the authoritative nameserver to send updates.

    .PARAMETER DDNSPort
        The port number the nameserver is listening on. Default is 53.

    .PARAMETER DDNSKeyName
        When using TSIG authentication, the name of the key you are using.

    .PARAMETER DDNSKeyType
        When using TSIG authentication, the type of key you are using. Accepts hmac-md5, hmac-sha1, hmac-sha224, hmac-sha256, hmac-sha384, and hmac-sha512.

    .PARAMETER DDNSKeyValue
        When using TSIG authentication, the value of the key you are using. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DDNSKeyValueInsecure
        When using TSIG authentication, the value of the key you are using. This standard String version may be used on any OS.

    .PARAMETER DDNSExePath
        The path to the nsupdate executable. The default is just 'nsupdate' which will use the first copy found in the PATH environment variable.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtRFC2136 '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com'

        Adds the specified TXT record with the specified value using unauthenticated RFC2136.

    .EXAMPLE
        $tsigParams = @{DDNSKeyName='key-name';DDNSKeyType='hmac-sha256';DDNSKeyValueInsecure='key-value'}
        PS C:\>Add-DnsTxtRFC2136 '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com' @tsigParams

        Adds the specified TXT record with the specified value using RFC2136 with SHA256 TSIG authentication.
    #>
}

function Remove-DnsTxtRFC2136 {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$DDNSNameserver,
        [string]$DDNSPort=53,
        [string]$DDNSKeyName,
        [ValidateSet('hmac-md5','hmac-sha1','hmac-sha224','hmac-sha256','hmac-sha384','hmac-sha512')]
        [string]$DDNSKeyType,
        [Parameter(ParameterSetName='Secure')]
        [securestring]$DDNSKeyValue,
        [Parameter(ParameterSetName='Insecure')]
        [string]$DDNSKeyValueInsecure,
        [string]$DDNSExePath='nsupdate',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext key value if it was specified
    if ($DDNSKeyValue -and 'Secure' -eq $PSCmdlet.ParameterSetName) {
        $DDNSKeyValueInsecure = (New-Object PSCredential "user",$DDNSKeyValue).GetNetworkCredential().Password
    }

    $zoneName = Find-DDNSRootDomain $RecordName $DDNSNameserver
    if (-not $zoneName) {
        throw "Unable to find authoritative domain for $RecordName on $DDNSNameserver"
    }
    Write-Verbose "Found authoritative zone $zoneName"

    # The nice thing about RFC2136 is that BIND doesn't care if you send duplicate updates
    # for the same record and value. So we don't need to check whether the record already
    # exists or not. Even if you're removing a record that's already gone, it still works.

    # build the params we'll send to the update function
    $updateParams = @{
        RecordName = "$RecordName."
        TxtValue = $TxtValue
        Action = 'del'
        Zone = "$zoneName."
        Nameserver = $DDNSNameserver
        Port = $DDNSPort
        NSUpdatePath = $DDNSExePath
    }

    # add the TSIG params if they were included
    if ($DDNSKeyName -and $DDNSKeyType -and $DDNSKeyValueInsecure) {
        $updateParams.TsigKeyName = $DDNSKeyName
        $updateParams.TsigKeyType = $DDNSKeyType
        $updateParams.TsigKeyValue = $DDNSKeyValueInsecure
    }

    Write-Verbose "Removing $RecordName with value $TxtValue"
    Send-DynamicTXTUpdate @updateParams

    <#
    .SYNOPSIS
        Remove a DNS TXT record using RFC2136

    .DESCRIPTION
        Uses the nsupdate utility to send dynamic updates to an authoritative nameserver.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER DDNSNameserver
        The hostname or IP address of the authoritative nameserver to send updates.

    .PARAMETER DDNSPort
        The port number the nameserver is listening on. Default is 53.

    .PARAMETER DDNSKeyName
        When using TSIG authentication, the name of the key you are using.

    .PARAMETER DDNSKeyType
        When using TSIG authentication, the type of key you are using. Accepts hmac-md5, hmac-sha1, hmac-sha224, hmac-sha256, hmac-sha384, and hmac-sha512.

    .PARAMETER DDNSKeyValue
        When using TSIG authentication, the value of the key you are using. This SecureString version can only be used on Windows or any OS with PowerShell 6.2+.

    .PARAMETER DDNSKeyValueInsecure
        When using TSIG authentication, the value of the key you are using. This standard String version may be used on any OS.

    .PARAMETER DDNSExePath
        The path to the nsupdate executable. The default is just 'nsupdate' which will use the first copy found in the PATH environment variable.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtRFC2136 '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com'

        Removes the specified TXT record with the specified value using unauthenticated RFC2136.

    .EXAMPLE
        $tsigParams = @{DDNSKeyName='key-name';DDNSKeyType='hmac-sha256';DDNSKeyValueInsecure='key-value'}
        PS C:\>Remove-DnsTxtRFC2136 '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com' @tsigParams

        Removes the specified TXT record with the specified value using RFC2136 with SHA256 TSIG authentication.
    #>
}

function Save-DnsTxtRFC2136 {
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

function Find-DDNSRootDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$Nameserver
    )

    if (!$script:RFC2136Zones) { $script:RFC2136Zones = @{} }

    if ($script:RFC2136Zones.ContainsKey($RecordName)) {
        return $script:RFC2136Zones.$RecordName
    }

    $pieces = $RecordName.Split('.')
    for ($j=1; $j -lt ($pieces.Count-1); $j++) {
        $zone = "$( $pieces[$j..($pieces.Count-1)] -join '.' )"
        Write-Debug "Checking if $Nameserver is authoritative for $zone"
        if (Test-AuthoritativeNameserver "$zone." $Nameserver) {
            $script:RFC2136Zones.$RecordName = $zone
            return $zone
        }
    }

    return $null
}

function Test-AuthoritativeNameserver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Zone,
        [Parameter(Mandatory,Position=1)]
        [string]$Nameserver
    )

    # For some inexplicable reason, neither .NET Framework or Core have a decent
    # built-in DNS library and taking on a 3rd party library dependency for something
    # this simple would be wasteful. So we need to shell out to the native nslookup or
    # dig executables in order to make the non-recursive SOA query to test whether
    # the specified nameserver is authoritative for the specified zone.

    if ($PSEdition -eq 'Desktop' -or $IsWindows) {
        # We're definitely on Windows, so we're using nslookup.
        Write-Debug 'Using nslookup'

        # We're going to use the full path to the Windows native nslookup.exe just in
        # case the user has added all of the BIND utilities to %PATH% which includes
        # its own copy of nslookup.
        $exePath = Join-Path $env:SystemRoot 'System32\nslookup.exe'
        $outlines = & $exePath -norecurse -type=soa $Zone $Nameserver 2>&1

        # ignore non-authoritative answers
        if ($true -in ($outlines | ForEach-Object { $_ -like 'Non-authoritative*' })) {
            Write-Debug 'Ignoring non-authoritative answer'
            return $false
        }

        # check for "primary name server = " to indicate a successful result
        if ($true -in ($outlines | ForEach-Object { $_ -like '*primary name server = *' })) {
            Write-Debug 'Found primary name server'
            return $true
        } else {
            Write-Debug 'No primary name server in output'
            return $false
        }
    }
    else {
        # Any other OS should have a native dig command
        Write-Debug 'Using dig'

        $outlines = & dig "@$Nameserver" $Zone soa +norecurse 2>&1

        # ignore non-authoritative answers
        if ($true -notin ($outlines | ForEach-Object { $_ -like ';; flags: * aa *' })) {
            Write-Debug 'Ignoring non-authoritative answer'
            return $false
        }

        # check for ANSWER SECTION
        if ($true -in ($outlines | ForEach-Object { $_ -eq ';; ANSWER SECTION:' })) {
            Write-Debug 'Found answer section'
            return $true
        } else {
            Write-Debug 'No answer section in output'
            return $false
        }
    }
}

function Send-DynamicTXTUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordName,
        [Parameter(Mandatory)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [ValidateSet('add','del')]
        [string]$Action,
        [Parameter(Mandatory)]
        [string]$Zone,
        [Parameter(Mandatory)]
        [string]$Nameserver,
        [int]$Port=53,
        [string]$TsigKeyName,
        [ValidateSet('hmac-md5','hmac-sha1','hmac-sha224','hmac-sha256','hmac-sha384','hmac-sha512')]
        [string]$TsigKeyType,
        [string]$TsigKeyValue,
        [string]$NSUpdatePath='nsupdate'
    )

    # build the input array we're going to send to nsupdate via stdin
    $input = @(
        "server $Nameserver $Port"
        "key $($TsigKeyType):$TsigKeyName $TsigKeyValue"
        "zone $Zone"
        "update $Action $RecordName 60 TXT `"$TxtValue`""
        'send'
        'answer'
    )

    # remove the "key" line if those variables were empty
    if (-not $TsigKeyName -or -not $TsigKeyType -or -not $TsigKeyValue) {
        Write-Debug "Using unauthenticated update"
        $input = $input[0,2,3,4,5]
    } else {
        Write-Debug "Using TSIG authentication with key $TsigKeyName"
    }

    try {
        $answerLines = $input | & $NSUpdatePath 2>&1
    } catch { throw }

    if ($true -notin ($answerLines | ForEach-Object { $_ -like '* status: NOERROR,*' })) {
        $answerLines | ForEach-Object { Write-Verbose $_ }
        throw "Unexpected output from nsupdate command. Use -Verbose for details."
    }
}
