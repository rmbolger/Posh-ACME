<#
.SYNOPSIS
    Posh-ACME DNS-01 plugin for Hosting.nl (api.hosting.nl)

.DESCRIPTION
    Uses the Hosting.nl REST API to manage TXT records for DNS-01 validation.
    Auth is a single static header (API-TOKEN), no login/token-exchange step.

.NOTES
    API docs: https://api.hosting.nl/api/documentation
    Reference client: lego's Hosting.nl provider (github.com/go-acme/lego,
    providers/dns/hostingnl), used to confirm the wire format below since
    Hosting.nl's own OpenAPI spec doesn't spell out the TXT quoting behavior.
#>

function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$HNLToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$HNLTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $RecordName = $RecordName.TrimEnd('.')

    $token = if ($PSCmdlet.ParameterSetName -eq 'Secure') {
        Unprotect-HNLSecureString -SecureString $HNLToken
    } else {
        $HNLTokenInsecure
    }

    $domain = Find-HNLZone -RecordName $RecordName -Token $token
    if (-not $domain) {
        throw "HostingNL: no domain in this account matches $RecordName"
    }

    $records = @((Invoke-HNLRest -Token $token -Method Get -Path "/domains/$domain/dns").data)

    $already = $records | Where-Object {
        $_.type -eq 'TXT' -and $_.name -eq $RecordName -and $_.content.Trim('"') -eq $TxtValue
    }
    if ($already) {
        Write-Verbose "HostingNL: TXT record for $RecordName with this value already exists. Nothing to do."
        return
    }

    # content is wrapped in literal double quotes to match lego's Hosting.nl
    # provider, which sends strconv.Quote(value). Hosting.nl stores whatever
    # is sent, quotes included, so a plugin that omits them writes a record
    # that reads back differently than one lego wrote. Matching the quoting
    # keeps Get-DnsTxt/Remove-DnsTxt comparisons correct either way.
    $body = @(
        @{
            name    = $RecordName
            type    = 'TXT'
            content = ('"{0}"' -f $TxtValue)
            ttl     = 300
        }
    )

    $null = Invoke-HNLRest -Token $token -Method Post -Path "/domains/$domain/dns" -Body $body

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hosting.nl.

    .DESCRIPTION
        Finds the domain that owns RecordName, checks whether a matching TXT
        record already exists, and if not, creates one via the Hosting.nl API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HNLToken
        The Hosting.nl API token, as a SecureString.

    .PARAMETER HNLTokenInsecure
        The Hosting.nl API token, as a plain string. Not recommended except
        for testing or headless automation where SecureString isn't practical.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'HostingNL API Token' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HNLToken $token

        Adds the record using a SecureString token (recommended).

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -HNLTokenInsecure 'my-api-token'

        Adds the record using a plain-string token, for headless automation.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=2)]
        [securestring]$HNLToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=2)]
        [string]$HNLTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $RecordName = $RecordName.TrimEnd('.')

    $token = if ($PSCmdlet.ParameterSetName -eq 'Secure') {
        Unprotect-HNLSecureString -SecureString $HNLToken
    } else {
        $HNLTokenInsecure
    }

    $domain = Find-HNLZone -RecordName $RecordName -Token $token
    if (-not $domain) {
        throw "HostingNL: no domain in this account matches $RecordName"
    }

    $records = @((Invoke-HNLRest -Token $token -Method Get -Path "/domains/$domain/dns").data)

    $match = $records | Where-Object {
        $_.type -eq 'TXT' -and $_.name -eq $RecordName -and $_.content.Trim('"') -eq $TxtValue
    } | Select-Object -First 1

    if (-not $match) {
        Write-Verbose "HostingNL: TXT record for $RecordName with this value does not exist. Nothing to do."
        return
    }

    $body = @(@{ id = $match.id })

    $null = Invoke-HNLRest -Token $token -Method Delete -Path "/domains/$domain/dns" -Body $body

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Hosting.nl.

    .DESCRIPTION
        Finds the domain that owns RecordName, looks up the matching TXT
        record by name and value, and deletes it by id via the Hosting.nl API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HNLToken
        The Hosting.nl API token, as a SecureString.

    .PARAMETER HNLTokenInsecure
        The Hosting.nl API token, as a plain string. Not recommended except
        for testing or headless automation where SecureString isn't practical.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'HostingNL API Token' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HNLToken $token

        Removes the record using a SecureString token (recommended).

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -HNLTokenInsecure 'my-api-token'

        Removes the record using a plain-string token, for headless automation.
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
        Hosting.nl's add/delete endpoints apply immediately, so there is no
        separate commit step.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

function Get-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=1)]
        [securestring]$HNLToken,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=1)]
        [string]$HNLTokenInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $RecordName = $RecordName.TrimEnd('.')

    $token = if ($PSCmdlet.ParameterSetName -eq 'Secure') {
        Unprotect-HNLSecureString -SecureString $HNLToken
    } else {
        $HNLTokenInsecure
    }

    $domain = Find-HNLZone -RecordName $RecordName -Token $token
    if (-not $domain) {
        throw "HostingNL: no domain in this account matches $RecordName"
    }

    $records = @((Invoke-HNLRest -Token $token -Method Get -Path "/domains/$domain/dns").data)

    $records |
        Where-Object { $_.type -eq 'TXT' -and $_.name -eq $RecordName } |
        ForEach-Object { $_.content.Trim('"') }

    <#
    .SYNOPSIS
        Returns the TXT record values currently set for a given record name.

    .DESCRIPTION
        Finds the domain that owns RecordName and returns the (quote-stripped)
        content of every TXT record at that name. Not called by Posh-ACME
        itself; useful for manual verification against a live account.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER HNLToken
        The Hosting.nl API token, as a SecureString.

    .PARAMETER HNLTokenInsecure
        The Hosting.nl API token, as a plain string. Not recommended except
        for testing or headless automation where SecureString isn't practical.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $token = Read-Host 'HostingNL API Token' -AsSecureString
        Get-DnsTxt '_acme-challenge.example.com' -HNLToken $token
    #>
}

############################
# Helper Functions
############################

# API docs: https://api.hosting.nl/api/documentation

$script:HNLApiRoot = 'https://api.hosting.nl'

if (-not $script:HNLDomainCache) { $script:HNLDomainCache = $null }

# Make sure TLS 1.2 is available for the api.hosting.nl calls. Posh-ACME
# already sets this process-wide before a plugin loads; this only matters if
# the file is dot-sourced standalone on Windows PowerShell 5.1, whose default
# can still be TLS 1.0/1.1. OR it in rather than overwrite so we don't disable
# protocols the host relies on; harmless no-op on PowerShell 7+.
try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    Write-Debug "HostingNL: could not set TLS 1.2 (likely already modern): $($_.Exception.Message)"
}

function Unprotect-HNLSecureString {
    [CmdletBinding()]
    param([Parameter(Mandatory)][securestring]$SecureString)
    (New-Object System.Management.Automation.PSCredential('a', $SecureString)).GetNetworkCredential().Password

    <#
    .SYNOPSIS
        Converts a SecureString to a plain string.

    .DESCRIPTION
        Returns the plaintext of a SecureString so it can be sent in the
        API-TOKEN header. Uses the PSCredential round-trip, which works on both
        Windows PowerShell 5.1 and PowerShell 7+.

    .PARAMETER SecureString
        The SecureString to convert.

    .OUTPUTS
        The plaintext string.
    #>
}

# Wraps Invoke-RestMethod with the Hosting.nl auth header and error shape.
# Hosting.nl reports errors as either {"error": "..."} or
# {"errors": {"message": "..."}} in the response body rather than through
# HTTP status text alone, so a plain Invoke-RestMethod failure would surface
# a generic "400 Bad Request" instead of the actual reason. This pulls that
# message out of the error response and rethrows it, falling back to the raw
# error if the body doesn't match either shape.
function Invoke-HNLRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Token,
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        [object]$Body
    )

    $params = @{
        Uri         = "$script:HNLApiRoot$Path"
        Method      = $Method
        Headers     = @{ 'API-TOKEN' = $Token; 'Accept' = 'application/json' }
        ContentType = 'application/json'
        ErrorAction = 'Stop'
        Verbose     = $false
    }
    if ($PSBoundParameters.ContainsKey('Body')) {
        # Pass -InputObject, not the pipeline. Piping a single-element array into
        # ConvertTo-Json unrolls it and emits a JSON object ({...}); the API's
        # add/delete endpoints require an array ([{...}]). -InputObject keeps the
        # array shape for one or many records. Verified on PS 7 and WinPS 5.1.
        $params.Body = (ConvertTo-Json -InputObject $Body -Depth 5)
    }

    try {
        Write-Debug "$Method $($params.Uri)"
        return Invoke-RestMethod @params @script:UseBasic
    } catch {
        $apiMessage = $null
        $errResp = $_.ErrorDetails.Message
        if ($errResp) {
            try {
                $parsed = $errResp | ConvertFrom-Json
                if ($parsed.error) { $apiMessage = $parsed.error }
                elseif ($parsed.errors.message) { $apiMessage = $parsed.errors.message }
            } catch {
                Write-Debug "HostingNL: error response body was not JSON: $errResp"
            }
        }
        if ($apiMessage) {
            throw "HostingNL: $Method $Path failed: $apiMessage"
        }
        throw
    }

    <#
    .SYNOPSIS
        Calls the Hosting.nl REST API.

    .DESCRIPTION
        Wraps Invoke-RestMethod with the API-TOKEN header and JSON content type,
        serializes any body to a JSON array, and on failure rethrows the message
        Hosting.nl returns in the response body instead of a generic HTTP status.

    .PARAMETER Token
        The Hosting.nl API token, as plaintext.

    .PARAMETER Method
        The HTTP method: Get, Post, or Delete.

    .PARAMETER Path
        The request path appended to https://api.hosting.nl, for example /domains.

    .PARAMETER Body
        Optional request body (a PowerShell object or array) sent as JSON.

    .OUTPUTS
        The parsed response object.
    #>
}

# Pages through GET /domains (Hosting.nl caps the response per call, hence
# limit/offset) and returns the longest domain name that owns RecordName,
# the same "prefer the longest owned match" rule the TransIP plugin uses.
# Needed here because an account can hold both a parent and a delegated
# child zone. Results are cached per plugin invocation of the dot-sourced
# script; Add/Remove/Get each get a fresh process from Posh-ACME per run.
function Find-HNLZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RecordName,
        [Parameter(Mandatory)][string]$Token
    )

    # $null (not just falsy) means "not fetched yet": an account with zero domains
    # caches as @(), which is falsy, so a -not guard would re-page every call.
    if ($null -eq $script:HNLDomainCache) {
        $limit = 100
        $offset = 0
        $all = @()
        do {
            $page = Invoke-HNLRest -Token $Token -Method Get -Path "/domains?limit=$limit&offset=$offset"
            $pageData = @($page.data)
            $all += $pageData
            $offset += $limit
        } while ($pageData.Count -ge $limit)

        $script:HNLDomainCache = @($all | ForEach-Object { $_.domain } | Where-Object { $_ })
    }

    $cleanName = $RecordName.TrimEnd('.')
    $best = $null
    foreach ($d in $script:HNLDomainCache) {
        # -like, not .EndsWith: the apex -eq test above is case-insensitive, and DNS
        # names are case-insensitive, so the suffix test must be too (.EndsWith is a
        # case-sensitive .NET call). Domain names contain no -like wildcard
        # metacharacters, so $d is safe as the pattern. Same rule as the TransIP plugin.
        if ($cleanName -eq $d -or $cleanName -like "*.$d") {
            if (-not $best -or $d.Length -gt $best.Length) {
                $best = $d
            }
        }
    }
    return $best

    <#
    .SYNOPSIS
        Finds the account domain that owns a record name.

    .DESCRIPTION
        Lists the account's domains (paged) and returns the longest one that
        equals, or is a parent of, RecordName. Returns $null when none matches.
        The domain list is cached for the life of the loaded script.

    .PARAMETER RecordName
        The full record name to place, for example _acme-challenge.example.com.

    .PARAMETER Token
        The Hosting.nl API token, as plaintext.

    .OUTPUTS
        The owning domain name, or $null.
    #>
}
