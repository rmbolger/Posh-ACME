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

    # Convert the secure token to a normal string
    $token = [pscredential]::new('a',$TechnitiumToken).GetNetworkCredential().Password

    # Build the API URL
    $baseUri = "$($TechnitiumProtocol)://$($TechnitiumServer)/api/zones/records/add"

    $queryParams = @{
        Uri = $baseUri
        Method = 'Get'
        Body = @{
            token = $token
            domain = $RecordName
            type = "TXT"
            ttl = $TechnitiumTTL
            text = $TxtValue
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }

    try {
        # ignore cert validation for the duration of the call
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOn }

        # Check if this exact value already exists
        $existing = Get-TechnitiumRecord -RecordName $RecordName -Token $token `
            -TechnitiumServer $TechnitiumServer -TechnitiumProtocol $TechnitiumProtocol `
            -TechnitiumIgnoreCert:$TechnitiumIgnoreCert
        
        if ($existing -and $TxtValue -in $existing.rData.text) {
            Write-Verbose "TXT record $RecordName already contains value $TxtValue (likely from previous run)"
            Write-Debug "Skipping add operation - record already exists with correct value"
            return
        }

        Write-Verbose "Adding TXT record $RecordName with value $TxtValue to Technitium DNS server $TechnitiumServer"
        $sanitizedBody = ($queryParams.Body | ConvertTo-Json).Replace($token,'********')
        Write-Debug "GET $baseUri`n$sanitizedBody"

        $result = Invoke-RestMethod @queryParams @script:UseBasic

        if ($result.status -ne "ok") {
            throw "Technitium API returned status: $($result.status). Response: $($result | ConvertTo-Json -Compress)"
        }

        Write-Verbose "Successfully added TXT record $RecordName"
    } catch {
        Write-Error "Failed to add TXT record to Technitium DNS: $_"
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

    # Convert the secure token to a normal string
    $token = [pscredential]::new('a',$TechnitiumToken).GetNetworkCredential().Password

    # Build the API URL
    $baseUri = "$($TechnitiumProtocol)://$($TechnitiumServer)/api/zones/records/delete"

    $queryParams = @{
        Uri = $baseUri
        Method = 'Get'
        Body = @{
            token = $token
            domain = $RecordName
            type = "TXT"
            text = $TxtValue
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }

    try {
        # ignore cert validation for the duration of the call
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOn }

        # Check if record exists before trying to delete
        $existing = Get-TechnitiumRecord -RecordName $RecordName -Token $token `
            -TechnitiumServer $TechnitiumServer -TechnitiumProtocol $TechnitiumProtocol `
            -TechnitiumIgnoreCert:$TechnitiumIgnoreCert
        
        if (!$existing -or $TxtValue -notin $existing.rData.text) {
            Write-Verbose "TXT record $RecordName with value $TxtValue not found (may have been already cleaned up)"
            Write-Debug "Skipping delete operation - record does not exist"
            return
        }

        Write-Verbose "Removing TXT record $RecordName with value $TxtValue from Technitium DNS server $TechnitiumServer"
        $sanitizedBody = ($queryParams.Body | ConvertTo-Json).Replace($token,'********')
        Write-Debug "GET $baseUri`n$sanitizedBody"

        $result = Invoke-RestMethod @queryParams @script:UseBasic

        if ($result.status -ne "ok") {
            throw "Technitium API returned status: $($result.status). Response: $($result | ConvertTo-Json -Compress)"
        }

        Write-Verbose "Successfully removed TXT record $RecordName"
    } catch {
        Write-Error "Failed to remove TXT record from Technitium DNS: $_"
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

function Get-TechnitiumRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordName,
        [Parameter(Mandatory)]
        [string]$Token,
        [Parameter(Mandatory)]
        [string]$TechnitiumServer,
        [Parameter(Mandatory)]
        [string]$TechnitiumProtocol,
        [switch]$TechnitiumIgnoreCert
    )

    $baseUri = "$($TechnitiumProtocol)://$($TechnitiumServer)/api/zones/records/get"
    
    $queryParams = @{
        Uri = $baseUri
        Method = 'Get'
        Body = @{
            token = $Token
            domain = $RecordName
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }

    try {
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOn }
        
        $result = Invoke-RestMethod @queryParams @script:UseBasic
        
        if ($result.status -eq "ok" -and $result.records) {
            return $result.records | Where-Object { $_.type -eq "TXT" }
        }
        return $null
    } catch {
        return $null
    } finally {
        if ($TechnitiumIgnoreCert) { Set-TechnitiumCertIgnoreOff }
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
