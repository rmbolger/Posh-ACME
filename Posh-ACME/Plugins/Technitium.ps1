function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [securestring]$TechnitiumToken,
        [Parameter(Mandatory,Position=3)]
        [string]$TechnitiumServer,
        [Parameter(Position=4)]
        [ValidateSet('https','http')]
        [string]$TechnitiumProtocol = 'https',
        [Parameter(Position=5)]
        [int]$TechnitiumTTL = 3600,
        [switch]$TechnitiumIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $commonParams = @{
        BaseUri = "$($TechnitiumProtocol)://$($TechnitiumServer)/api"
        Token = [pscredential]::new('a',$TechnitiumToken).GetNetworkCredential().Password
    }

    try {
        # ignore cert validation for the duration of the call
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOn }

        $resp = Invoke-Technitium 'zones/records/get' @{domain=$RecordName} @commonParams
        $txtRecs = $resp.response.records | Where-Object { $_.type -eq "TXT" }

        if ($txtRecs -and $TxtValue -in $txtRecs.rData.text) {
            Write-Debug "Record $RecordName with value $TxtValue already exists. Nothing to do."
            return
        }

        Write-Verbose "Adding TXT record $RecordName with value $TxtValue"
        $body = @{
            domain = $RecordName
            type = "TXT"
            ttl = $TechnitiumTTL
            text = $TxtValue
        }
        $null = Invoke-Technitium 'zones/records/add' $body @commonParams

        Write-Verbose "Successfully added TXT record $RecordName"
    } catch {
        throw
    } finally {
        # return cert validation back to normal
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOff }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Technitium DNS Server.

    .DESCRIPTION
        Add a DNS TXT record to Technitium DNS Server using the HTTP(S) API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER TechnitiumToken
        The Technitium DNS Server API authentication token.

    .PARAMETER TechnitiumServer
        The Technitium DNS Server hostname/IP and port (e.g., 'dns.example.com:5380' or '192.168.1.100:5380').

    .PARAMETER TechnitiumProtocol
        The protocol to use for API calls. Valid values are 'https' (default) or 'http'. HTTPS is strongly recommended for production use.

    .PARAMETER TechnitiumTTL
        The TTL of the new TXT record in seconds (default 3600).

    .PARAMETER TechnitiumIgnoreCert
        If specified, SSL certificate errors will be ignored (not recommended for production use).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = ConvertTo-SecureString 'your-api-token' -AsPlainText -Force
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token 'dns.example.com:5380'

        Adds a TXT record using HTTPS (default protocol).

    .EXAMPLE
        $token = ConvertTo-SecureString 'your-api-token' -AsPlainText -Force
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $token '192.168.1.100:5380' -TechnitiumProtocol 'http'

        Adds a TXT record using HTTP for troubleshooting.
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
        [securestring]$TechnitiumToken,
        [Parameter(Mandatory,Position=3)]
        [string]$TechnitiumServer,
        [Parameter(Position=4)]
        [ValidateSet('https','http')]
        [string]$TechnitiumProtocol = 'https',
        [Parameter(Position=5)]
        [int]$TechnitiumTTL = 3600,
        [switch]$TechnitiumIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $commonParams = @{
        BaseUri = "$($TechnitiumProtocol)://$($TechnitiumServer)/api"
        Token = [pscredential]::new('a',$TechnitiumToken).GetNetworkCredential().Password
    }

    try {
        # ignore cert validation for the duration of the call
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOn }

        $resp = Invoke-Technitium 'zones/records/get' @{domain=$RecordName} @commonParams
        $txtRecs = $resp.response.records | Where-Object { $_.type -eq "TXT" }

        if (-not $txtRecs -or $TxtValue -notin $txtRecs.rData.text) {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
            return
        }

        Write-Verbose "Removing TXT record $RecordName with value $TxtValue"
        $body = @{
            domain = $RecordName
            type = "TXT"
            text = $TxtValue
        }
        $null = Invoke-Technitium 'zones/records/delete' $body @commonParams

        Write-Verbose "Successfully removed TXT record $RecordName"
    } catch {
        throw
    } finally {
        # return cert validation back to normal
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOff }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Technitium DNS Server.

    .DESCRIPTION
        Remove a DNS TXT record from Technitium DNS Server using the HTTP(S) API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER TechnitiumToken
        The Technitium DNS Server API authentication token.

    .PARAMETER TechnitiumServer
        The Technitium DNS Server hostname/IP and port (e.g., 'dns.example.com:5380' or '192.168.1.100:5380').

    .PARAMETER TechnitiumProtocol
        The protocol to use for API calls. Valid values are 'https' (default) or 'http'. HTTPS is strongly recommended for production use.

    .PARAMETER TechnitiumTTL
        The TTL parameter (included for consistency but not used in delete operations).

    .PARAMETER TechnitiumIgnoreCert
        If specified, SSL certificate errors will be ignored (not recommended for production use).

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = ConvertTo-SecureString 'your-api-token' -AsPlainText -Force
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token 'dns.example.com:5380'

        Removes a TXT record using HTTPS (default protocol).

    .EXAMPLE
        $token = ConvertTo-SecureString 'your-api-token' -AsPlainText -Force
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $token '192.168.1.100:5380' -TechnitiumProtocol 'http'

        Removes a TXT record using HTTP for troubleshooting.
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

# API Docs:
# https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md

function Set-TechnitiumCertIgnoreOn {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        # Core edition
        if (-not $script:UseBasic.SkipCertificateCheck) {
            Write-Debug "Disabling certificate validation for PS Core"
            # temporarily set skip to true
            $script:UseBasic.SkipCertificateCheck = $true
            # remember that we did
            $script:TechnitiumUnsetIgnoreAfter = $true
        }

    } else {
        Write-Debug "Disabling certificate validation for PS Desktop"
        # Desktop edition
        [CertValidation]::Ignore()
    }
}

function Set-TechnitiumCertIgnoreOff {
    [CmdletBinding()]
    param()

    if ($script:SkipCertSupported) {
        Write-Debug "Enabling certificate validation for PS Core"
        # Core edition
        if ($script:TechnitiumUnsetIgnoreAfter) {
            $script:UseBasic.SkipCertificateCheck = $false
            Remove-Variable TechnitiumUnsetIgnoreAfter -Scope Script
        }

    } else {
        # Desktop edition
        Write-Debug "Enabling certificate validation for PS Desktop"
        [CertValidation]::Restore()
    }
}

function Invoke-Technitium {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Endpoint,
        [Parameter(Mandatory, Position=1)]
        [hashtable]$Body,
        [Parameter(Mandatory, Position=2)]
        [string]$BaseUri,
        [Parameter(Mandatory, Position=3)]
        [string]$Token
    )

    $queryParams = @{
        Uri = "$BaseUri/$Endpoint"
        Method = 'Get'
        Body = $Body
        Verbose = $false
        ErrorAction = 'Stop'
    }
    # log the call without the token before we add it
    Write-Debug "GET $($queryParams.Uri)`n$($queryParams.Body | ConvertTo-Json)"
    # add the token
    $queryParams.Body.token = $Token

    try {
        $result = Invoke-RestMethod @queryParams @script:UseBasic
        if ($result.status -ne "ok") {
            throw "Technitium API returned status: $($result.status). Message: $($result.errorMessage)"
        }
        return $result
    } catch {
        throw
    }
}
