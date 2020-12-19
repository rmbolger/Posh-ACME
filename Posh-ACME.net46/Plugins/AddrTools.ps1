function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [securestring]$AddrToolsSecret,
        [string]$AddrToolsHost='challenges.addr.tools',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $secPlain = [pscredential]::new('a',$AddrToolsSecret).GetNetworkCredential().Password

    $queryParams = @{
        Uri = 'https://{0}' -f $AddrToolsHost
        Method = 'POST'
        Body = @{
            secret = 'REDACTED'
            txt = $TxtValue
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }
    # log with redacted secret
    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
    Write-Debug "$($queryParams.Method)  $($queryParams.Uri)`n$($queryParams.Body|ConvertTo-Json)"

    try {
        $queryParams.Body.secret = $secPlain
        $resp = Invoke-RestMethod @queryParams @script:UseBasic
        if (-not $resp.Trim() -eq 'OK') {
            Write-Warning "Addr.Tools returned: $($resp.Trim())"
        }
    } catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to challenges.addr.tools

    .DESCRIPTION
        Description for challenges.addr.tools

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER AddrToolsSecret
        The secret associated with your challenges.addr.tools subdomain.

    .PARAMETER AddrToolsHost
        If self-hosting, domain name of your challenges.addr.tools equivalent (e.g. challenges.example.com)

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

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
        [Parameter(Mandatory)]
        [securestring]$AddrToolsSecret,
        [string]$AddrToolsHost='challenges.addr.tools',
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $secPlain = [pscredential]::new('a',$AddrToolsSecret).GetNetworkCredential().Password

    $queryParams = @{
        Uri = 'https://{0}' -f $AddrToolsHost
        Method = 'DELETE'
        Body = @{
            secret = 'REDACTED'
            txt = $TxtValue
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }
    # log with redacted secret
    Write-Verbose "Deleting $RecordName with value $TxtValue"
    Write-Debug "$($queryParams.Method) $($queryParams.Uri)`n$($queryParams.Body|ConvertTo-Json)"

    try {
        $queryParams.Body.secret = $secPlain
        $resp = Invoke-RestMethod @queryParams @script:UseBasic
        if (-not $resp.Trim() -eq '') {
            Write-Warning "Addr.Tools returned: $($resp.Trim())"
        }
    } catch { throw }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER AddrToolsSecret
        The secret associated with your challenges.addr.tools subdomain.

    .PARAMETER AddrToolsHost
        If self-hosting, domain name of your challenges.addr.tools equivalent (e.g. challenges.example.com)

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

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

# https://challenges.addr.tools/

function Get-AddrToolsCNAME {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(Mandatory,Position=1)]
        [securestring]$AddrToolsSecret,
        [string]$AddrToolsHost='challenges.addr.tools'
    )

    $challengeSub = Get-AddrToolsSubdomain $AddrToolsSecret -AddrToolsHost $AddrToolsHost

    # Create a unique list of domains after stripping wildcards
    $Domain | Select-Object @{
        L='FQDN';  E={ '_acme-challenge.{0}' -f $_.TrimStart('*.') }
    },@{
        L='Target';E={ $challengeSub }
    } | Select-Object -Unique *
}

function Get-AddrToolsSubdomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [securestring]$AddrToolsSecret,
        [string]$AddrToolsHost='challenges.addr.tools'
    )

    if (-not $script:UseBasic) {
        $script:UseBasic = @{UseBasicParsing=$true}
    }

    # The subdomain for a give secret is the SHA-224 hash of the secret
    # prepended to the challenges FQDN. So by default:
    #     <sha224>.challenges.addr.tools
    #
    # Until we have a local SHA-224 hashing implementation, you can get this
    # value by querying the endpoint with just the secret and no other arguments.

    $secPlain = [pscredential]::new('a',$AddrToolsSecret).GetNetworkCredential().Password

    $queryParams = @{
        Uri = 'https://{0}' -f $AddrToolsHost
        Method = 'POST'
        Body = @{
            secret = $secPlain
        }
        Verbose = $false
        ErrorAction = 'Stop'
    }
    try {
        Write-Debug "POST $($queryParams.Uri)"
        $resp = Invoke-RestMethod @queryParams @script:UseBasic
    } catch { throw }

    return $resp.Trim().TrimEnd('.')
}
