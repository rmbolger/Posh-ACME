function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [string]$DDNSNameserver,
        [string]$DDNSPort=53,
        [string]$DDNSKeyName,
        [ValidateSet('hmac-md5','hmac-sha1','hmac-sha224','hmac-sha256','hmac-sha384','hmac-sha512')]
        [string]$DDNSKeyType,
        [Parameter(ParameterSetName='Secure')]
        [securestring]$DDNSKeyValue,
        [Parameter(ParameterSetName='DeprecatedInsecure')]
        [string]$DDNSKeyValueInsecure,
        [string]$DDNSExePath='nsupdate',
        [string[]]$DDNSZone,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext key value if it was specified
    if ($DDNSKeyValue -and 'Secure' -eq $PSCmdlet.ParameterSetName) {
        $DDNSKeyValueInsecure = [pscredential]::new('a',$DDNSKeyValue).GetNetworkCredential().Password
    }

    # The nice thing about RFC2136 is that BIND doesn't care if you send duplicate updates
    # for the same record and value. So we don't need to check whether the record already
    # exists or not. Even if you're removing a record that's already gone, it still works.

    # build the params we'll send to the update function
    $updateParams = @{
        RecordName = "$RecordName."
        TxtValue = $TxtValue
        Action = 'add'
        Port = $DDNSPort
        NSUpdatePath = $DDNSExePath
    }
    if ($DDNSNameserver) {
        $updateParams.Nameserver = $DDNSNameserver
    }


    # add the TSIG params if they were included
    if ($DDNSKeyName -and $DDNSKeyType -and $DDNSKeyValueInsecure) {
        $updateParams.TsigKeyName = $DDNSKeyName
        $updateParams.TsigKeyType = $DDNSKeyType
        $updateParams.TsigKeyValue = $DDNSKeyValueInsecure
    }

    # determine the correct zone if a zone list was specified
    $DDNSZone | Sort-Object -Descending { $_.Length } | ForEach-Object {
        if ($RecordName -like "*.$_") {
            Write-Debug "Matched $_ from zone list"
            $updateParams.Zone = "$_."
            return
        }
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
        When using TSIG authentication, the value of the key you are using.

    .PARAMETER DDNSKeyValueInsecure
        (DEPRECATED) When using TSIG authentication, the value of the key you are using.

    .PARAMETER DDNSExePath
        The path to the nsupdate executable. The default is just 'nsupdate' which will use the first copy found in the PATH environment variable.

    .PARAMETER DDNSZone
        The zone(s) that contain the record being updated. Normally, nsupdate does a TSIG authenticated SOA query to determine the zone. But in some environments, the SOA query fails and this allows you to bypass it.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com'

        Adds the specified TXT record with the specified value using unauthenticated RFC2136.

    .EXAMPLE
        $tsigKey = Read-Host 'TSIG Key' -AsSecureString
        $tsigParams = @{DDNSKeyName='key-name';DDNSKeyType='hmac-sha256';DDNSKeyValue=$tsigKey}
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com' @tsigParams

        Adds the specified TXT record with the specified value using RFC2136 with SHA256 TSIG authentication.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [string]$DDNSNameserver,
        [string]$DDNSPort=53,
        [string]$DDNSKeyName,
        [ValidateSet('hmac-md5','hmac-sha1','hmac-sha224','hmac-sha256','hmac-sha384','hmac-sha512')]
        [string]$DDNSKeyType,
        [Parameter(ParameterSetName='Secure')]
        [securestring]$DDNSKeyValue,
        [Parameter(ParameterSetName='DeprecatedInsecure')]
        [string]$DDNSKeyValueInsecure,
        [string]$DDNSExePath='nsupdate',
        [string[]]$DDNSZone,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # grab the cleartext key value if it was specified
    if ($DDNSKeyValue -and 'Secure' -eq $PSCmdlet.ParameterSetName) {
        $DDNSKeyValueInsecure = [pscredential]::new('a',$DDNSKeyValue).GetNetworkCredential().Password
    }

    # The nice thing about RFC2136 is that BIND doesn't care if you send duplicate updates
    # for the same record and value. So we don't need to check whether the record already
    # exists or not. Even if you're removing a record that's already gone, it still works.

    # build the params we'll send to the update function
    $updateParams = @{
        RecordName = "$RecordName."
        TxtValue = $TxtValue
        Action = 'del'
        Port = $DDNSPort
        NSUpdatePath = $DDNSExePath
    }
    if ($DDNSNameserver) {
        $updateParams.Nameserver = $DDNSNameserver
    }

    # add the TSIG params if they were included
    if ($DDNSKeyName -and $DDNSKeyType -and $DDNSKeyValueInsecure) {
        $updateParams.TsigKeyName = $DDNSKeyName
        $updateParams.TsigKeyType = $DDNSKeyType
        $updateParams.TsigKeyValue = $DDNSKeyValueInsecure
    }

    # determine the correct zone if a zone list was specified
    $DDNSZone | Sort-Object -Descending { $_.Length } | ForEach-Object {
        if ($RecordName -like "*.$_") {
            Write-Debug "Matched $_ from zone list"
            $updateParams.Zone = "$_."
            return
        }
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
        When using TSIG authentication, the value of the key you are using.

    .PARAMETER DDNSKeyValueInsecure
        (DEPRECATED) When using TSIG authentication, the value of the key you are using.

    .PARAMETER DDNSExePath
        The path to the nsupdate executable. The default is just 'nsupdate' which will use the first copy found in the PATH environment variable.

    .PARAMETER DDNSZone
        The zone(s) that contain the record being updated. Normally, nsupdate does a TSIG authenticated SOA query to determine the zone. But in some environments, the SOA query fails and this allows you to bypass it.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com'

        Removes the specified TXT record with the specified value using unauthenticated RFC2136.

    .EXAMPLE
        $tsigKey = Read-Host 'TSIG Key' -AsSecureString
        $tsigParams = @{DDNSKeyName='key-name';DDNSKeyType='hmac-sha256';DDNSKeyValue=$tsigKey}
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -DDNSNameserver 'ns.example.com' @tsigParams

        Removes the specified TXT record with the specified value using RFC2136 with SHA256 TSIG authentication.
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
        [string]$Nameserver,
        [int]$Port=53,
        [string]$TsigKeyName,
        [ValidateSet('hmac-md5','hmac-sha1','hmac-sha224','hmac-sha256','hmac-sha384','hmac-sha512')]
        [string]$TsigKeyType,
        [string]$TsigKeyValue,
        [string]$NSUpdatePath='nsupdate',
        [string]$Zone
    )

    # build the input array we're going to send to nsupdate via stdin
    if ($Nameserver) {
        $cmds = @("server $Nameserver $Port")
    } else {
        $cmds = @()
    }

    # add the zone if specified
    if ($Zone) {
        $cmds += @("zone $Zone")
    }

    # add the TSIG key if specified
    if ($TsigKeyName -and $TsigKeyType -and $TsigKeyValue) {
        Write-Debug "Using TSIG authentication with key $TsigKeyName"
        $cmds += @("key $($TsigKeyType):$TsigKeyName $TsigKeyValue")
    } else {
        Write-Debug "Using unauthenticated update"
    }

    # add the rest
    $cmds += @(
        "update $Action $RecordName 60 TXT `"$TxtValue`""
        'send'
        'answer'
    )

    if (-not $TsigKeyValue) {
        Write-Debug "Sending the following to nsupdate:`n$(($cmds -join "`n"))"
    } else {
        Write-Debug "Sending the following to nsupdate:`n$(($cmds -join "`n").Replace($TsigKeyValue,'************'))"
    }

    try {
        $answerLines = $cmds | & $NSUpdatePath 2>&1
        $exitCode = $LASTEXITCODE
    } catch { throw }

    if ($exitCode -ne 0) {
        Write-Verbose "nsupdate output:`n$($answerLines -join "`n")"
        throw "nsupdate returned non-zero exit code which indicates failure. Check -Verbose output for details."
    } else {
        # write the nsupdate output to Debug just in case
        Write-Debug "nsupdate output:`n$($answerLines -join "`n")"
    }

}
