function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [pscredential]$SolidCredential,
        [Parameter(Mandatory,Position=3)]
        [string]$SolidAPIHost,
        [Parameter(Position=4)]
        [string]$SolidDNSServer,
        [Parameter(Position=5)]
        [string]$SolidView,
        [switch]$SolidIgnoreCert,
        [switch]$SolidTokenAuth,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # SOLIDServer's `dns_rr_add` allows us to add an FQDN and it will find the appropriate zone
    # assuming the supplied Server and View contain a matching zone. The add_flag=new_edit param
    # also allows us to do a blind add without checking if the record already exists first which
    # is extra nice.

    # WARNING: If the view is left empty and there are multiple zones that match in different views,
    # the record seems to get added to all of them. Not sure if this also applies to matching zones
    # on different servers.

    $queryParams = @{
        APIHost = $SolidAPIHost
        Credential = $SolidCredential
        Endpoint = 'dns_rr_add'
        Method = 'POST'
        Body = @{
            rr_name = $RecordName
            value1 = $TxtValue
            rr_type = 'TXT'
            rr_ttl = 30
            add_flag = 'new_edit'
            check_value = 'yes'
            dns_name = $SolidDNSServer
            dnsview_name = $SolidView
        }
        IgnoreCert = $SolidIgnoreCert.IsPresent
        TokenAuth = $SolidTokenAuth.IsPresent
    }
    Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
    $resp = Invoke-SolidRequest @queryParams
    Write-Debug "Response: $($resp | ConvertTo-Json)"

    <#
    .SYNOPSIS
        Add a DNS TXT record to EfficientIP SOLIDServer.

    .DESCRIPTION
        Add a DNS TXT record to EfficientIP SOLIDServer.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SolidCredential
        The SOLIDServer Username and Password.

    .PARAMETER SolidAPIHost
        The EfficientIP SOLIDServer Hostname.

    .PARAMETER SolidDNSServer
        The EfficientIP SOLIDServer DNS server.

    .PARAMETER SolidView
        The EfficientIP SOLIDServer DNS view.

    .PARAMETER SolidIgnoreCert
        When set, certificate validation will be disabled for connections to the SOLIDServer.

    .PARAMETER SolidTokenAuth
        When set, the username and password in SolidCredential will be used as API Token and Secret

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $cred 'eip.local' 'smart.local' 'external'

        Adds a TXT record for the specified site with the specified value.
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
        [pscredential]$SolidCredential,
        [Parameter(Mandatory,Position=3)]
        [string]$SolidAPIHost,
        [Parameter(Position=4)]
        [string]$SolidDNSServer,
        [Parameter(Position=5)]
        [string]$SolidView,
        [switch]$SolidIgnoreCert,
        [switch]$SolidTokenAuth,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Find the rr_id of the record if it exists
    $queryParams = @{
        APIHost = $SolidAPIHost
        Credential = $SolidCredential
        Endpoint = 'dns_rr_list'
        Method = 'GET'
        Body = @{
            SELECT = 'rr_id,rr_full_name,rr_type,value1,dnsview_name,vdns_parent_id'
            WHERE = "dnszone_type='master' AND rr_full_name='$RecordName' AND rr_type='TXT' AND value1='$TxtValue'"
        }
        IgnoreCert = $SolidIgnoreCert.IsPresent
        TokenAuth = $SolidTokenAuth.IsPresent
    }
    # Add optional fields
    if ($SolidDNSServer) {
        $queryParams.Body.WHERE += " AND dns_name='$SolidDNSServer'"
    }
    if ($SolidView) {
        $queryParams.Body.WHERE += " AND dnsview_name='$SolidView'"
    }
    $resp = Invoke-SolidRequest @queryParams

    if ($resp.rr_id) {
        # In case we have multiple record matches, delete all of them
        $resp.rr_id | ForEach-Object {
            $queryParams.Endpoint = 'dns_rr_delete'
            $queryParams.Method = 'DELETE'
            $queryParams.Body = @{ rr_id = $_ }
            Write-Verbose "Removing TXT record rr_id $_ - $RecordName with value $TxtValue"
            $resp = Invoke-SolidRequest @queryParams
            Write-Debug "Response: $($resp | ConvertTo-Json)"
        }
    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from EfficientIP SOLIDServer.

    .DESCRIPTION
        Remove a DNS TXT record from EfficientIP SOLIDServer.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SolidCredential
        The SOLIDServer Username and Password.

    .PARAMETER SolidAPIHost
        The EfficientIP SOLIDServer Hostname.

    .PARAMETER SolidDNSServer
        The EfficientIP SOLIDServer DNS server.

    .PARAMETER SolidView
        The EfficientIP SOLIDServer DNS view.

    .PARAMETER SolidIgnoreCert
        When set, certificate validation will be disabled for connections to the SOLIDServer.

    .PARAMETER SolidTokenAuth
        When set, the username and password in SolidCredential will be used as API Token and Secret

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $cred 'eip.local' 'smart.local' 'external'

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

# API docs are only available as PDF for customers

function Invoke-SolidRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$APIHost,
        [Parameter(Mandatory)]
        [pscredential]$Credential,
        [Parameter(Mandatory)]
        [string]$Endpoint,
        [string]$Method = 'GET',
        [hashtable]$Body,
        [switch]$IgnoreCert,
        [switch]$TokenAuth
    )

    # build the base query
    $queryParams = @{
        Uri = 'https://{0}/rest/{1}' -f $APIHost,$Endpoint
        Method = $Method
        Headers = @{
            Accept = 'application/json'
        }
        ErrorAction = 'Stop'
        Verbose = $false
    }

    # add the body if necessary
    if ($Body) {
        if ($Method -eq 'GET') {
            # Passing a hashtable as-is to -Body would normally auto-encode into
            # key=value querystring pairs under the hood. But when using token auth,
            # we need to sign the full Uri+Querystring. So we're going to encode
            # the querystring ourselves and just append it to the Uri regardless
            # of the auth type.
            $querystring = ConvertTo-QueryString $Body
            $queryParams.Uri += '?{0}' -f $querystring
        } else {
            # Everything else is JSON
            $queryParams.ContentType = 'application/json; charset=utf-8'
            $queryParams.Body = $Body | ConvertTo-Json -Compress
        }
    }

    # Grab the plaintext password and build the auth header
    $pwdPlain = $Credential.GetNetworkCredential().Password

    if ($TokenAuth) {
        $timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        Write-Debug "Using token auth with token prefix $($Credential.UserName.Substring(0,5)) at $timestamp"
        $strToHash = "{0}`n{1}`n{2}`n{3}" -f $pwdPlain,$timestamp,$Method,$queryParams.Uri
        $signature = Get-SHA3_256 $strToHash
        $queryParams.Headers.'X-SDS-TS' = $timestamp
        $queryParams.Headers.Authorization = 'SDS {0}:{1}' -f $Credential.UserName,$signature

    } else {
        Write-Debug "Using Basic auth with username $($Credential.UserName)"
        $basicAuth = [Convert]::ToBase64String(
            [Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $Credential.Username, $pwdPlain))
        )
        $queryParams.Headers.Authorization = 'Basic {0}' -f $basicAuth
    }
    Write-Debug "$Method $($queryParams.Uri)"
    if ($Method -ne 'GET') {
        Write-Debug ($Body | ConvertTo-Json)
    }

    try {
        # ignore cert validation for the duration of the call
        if ($SolidIgnoreCert) { Set-CertIgnoreOn }

        $result = Invoke-RestMethod @queryParams @script:UseBasic
    } catch {
        $response = $_.Exception.Response
        # deal with bad credentials first
        if (401 -eq $response.StatusCode) {
            throw "SOLIDServer returned an Unauthorized error. Check for bad credentials."
        }
        # The web exception types thrown between PowerShell editions are different.
        # So we need to string match the type names in order to process each correctly.
        $exType = $_.Exception.GetType().FullName

        if ('System.Net.WebException' -eq $exType) {    # Desktop edition
            # grab the raw response body from System.Net.HttpWebResponse
            $sr = [IO.StreamReader]::new($response.GetResponseStream())
            $sr.BaseStream.Position = 0
            $sr.DiscardBufferedData()
            $errBody = $sr.ReadToEnd()
            $sr.Close()

        } elseif ('Microsoft.PowerShell.Commands.HttpResponseException' -eq $exType) {
            # Core edition
            # Grab the "processed" response body
            $errBody = $_.ErrorDetails.Message

        } else { throw }

        Write-Debug "Response Code $($response.StatusCode.value__), Body: `n$errBody"
        try {
            $result = $errBody | ConvertFrom-Json
        } catch {
            throw "SOLIDServer returned a non-JSON error body."
        }

    } finally {
        # return cert validation back to normal
        if ($SolidIgnoreCert) { Set-CertIgnoreOff }
    }

    if ($result.errno -and $result.errno -gt 0) {
        $msg = $result.errmsg
        if (-not $msg) { $msg = $result.msg }
        throw "SOLIDServer returned error $($result.errno): $msg. (Enable debug output for full error body)"
    }

    $result
}

function Set-CertIgnoreOn {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if (-not $script:UseBasic.SkipCertificateCheck) {
            # temporarily set skip to true
            $script:UseBasic.SkipCertificateCheck = $true
            # remember that we did
            $script:SolidUnsetIgnoreAfter = $true
        }

    } else {
        # Desktop edition
        [CertValidation]::Ignore()
    }
}

function Set-CertIgnoreOff {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if ($script:SolidUnsetIgnoreAfter) {
            $script:UseBasic.SkipCertificateCheck = $false
            Remove-Variable SolidUnsetIgnoreAfter -Scope Script
        }

    } else {
        # Desktop edition
        [CertValidation]::Restore()
    }
}

function Get-SHA3_256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$InputString
    )

    # PowerShell 7.4+ (.NET 8+) have a native SHA3_256 class in System.Security.Cryptography.
    # However, it only works on Windows 11 23H2+ and Linux with OpenSSL 1.1.1+.
    # So for everything else, we'll try to use the BouncyCastle equivalent in
    # Org.BouncyCastle.Crypto.Digests.Sha3Digest that gets loaded by the module.

    $inputBytes = [Text.Encoding]::UTF8.GetBytes($InputString)

    # Try native first
    try {
        $sha3 = [System.Security.Cryptography.SHA3_256]::Create()
        Write-Debug "Using Native SHA3-256"
        $hashBytes = $sha3.ComputeHash($inputBytes)
    } catch {
        try {
            $sha3 = [Org.BouncyCastle.Crypto.Digests.Sha3Digest]::new(256)
            Write-Debug "Using BouncyCastle SHA3-256"
            $hashBytes = [byte[]]::new($sha3.GetDigestSize())
            $sha3.BlockUpdate($inputBytes, 0, $inputBytes.Length)
            $null = $sha3.DoFinal($hashBytes, 0)
        } catch {
            throw "Unable to load SHA3_256 hashing library. Make sure Posh-ACME is imported."
        }
    }

    return [BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
}

function ConvertTo-QueryString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$InputData
    )

    Write-Debug "Converting to querystring`n$($InputData | ConvertTo-Json)"
    $encodedPairs = foreach ($kvp in $InputData.GetEnumerator()) {
        '{0}={1}' -f [uri]::EscapeDataString($kvp.Key),[uri]::EscapeDataString($kvp.Value)
    }
    return ($encodedPairs -join '&')
}
