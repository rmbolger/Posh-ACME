# [Writing a Validation Plugin for Posh-ACME](https://github.com/rmbolger/Posh-ACME/blob/main/Posh-ACME/Plugins/README.md)
#

function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Docs @ https://api.combell.com/v2/documentation#tag/DNS-records/paths/~1dns~1{domainName}~1records/post
    # HTTP POST https://api.combell.com/v2/dns/{domainName}/records
    #
    # TODO Can {domainName} be computed from $RecordName? If not, add $CombellDomainName param - Steven Volckaert, 27 August 2021.

    # Do work here to add the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Add a DNS TXT record via the Combell API.

    .DESCRIPTION
        Add a DNS TXT record via the Combell API.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Adds a TXT record for the specified site with the specified value.
    #>
}

# Copied from Akamai.ps1 - Steven Volckaert, 12 August 2021.
function Get-HMACSHA256Hash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Key,
        [Parameter(Mandatory,Position=1)]
        [string]$Message
    )

    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::ASCII.GetBytes($Key)
    $msgBytes = [Text.Encoding]::ASCII.GetBytes($Message)
    return [Convert]::ToBase64String($hmac.ComputeHash($msgBytes))
}

function Get-CombellHMAC {

    <#
    TODO Compute HMAC with the SHA-256 hashing algorithm; see
    - https://api.combell.com/v2/documentation#section/Authentication/Steps-to-generate-the-HMAC
    - https://gist.github.com/45413/da6eb16a8dcfc357b633050b3fc14e34

    Finally: Base64-encode the result of the hash function
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Do work here to remove the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Remove a DNS TXT record from <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

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
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, just
    # leave the function body empty.

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications.
    #>
}

############################
# Helper Functions
############################

# Add a commented link to API docs if they exist.

function Send-CombellHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Path,
        [Parameter(Position=1)]
        [ValidateSet('GET','PUT','POST','DELETE')]
        [string]$Method = 'GET',
        [string]$Body,

        [int]$MaxBody = 131072,

        [string]$AcceptHeader = 'application/json',
        [string]$ApiHost = 'api.combell.com',
        [Parameter(Mandatory)]
        [string]$ApiKey,
        [Parameter(Mandatory)]
        [string]$ApiSecret
    )

    # TODO Consider trimming '/' from the end of $Path, if it exists
    # TODO Consider to parameterize API version in paths "/v2/"


    # initialize some stuff we'll need for the signature process
    $uri = [uri]"https://$($ApiHost)/v2/$Path"
    $urlEncodedPath = [System.Net.WebUtility]::UrlEncode("/v2/$Path");
    $Method = $Method.ToLower();
    $unixTimestamp = [int][double]::Parse((Get-Date -UFormat %s));
    $nonce = (New-Guid).ToString()

    $hmacInputValue = "${ApiKey}${Method}${urlEncodedPath}${unixTimestamp}${nonce}";
    # TODO To support POSTs, $Body is not empty. In that case, $Body must be hashed (MD5), then Base64-encoded (or vice
    # versa - the order is unclear from https://api.combell.com/v2/documentation#section/Authentication/Steps-to-generate-the-HMAC
    # , and finally added to $hmacInputValue (concat at end)
    Write-Verbose "HMAC input value: $hmacInputValue";

    # TODO $sha256Hash = Get-HMACSHA256Hash $ApiSecret $hmacInputValue;
    # TODO $hmacSignature = Base64 encode $sha256Hash;


    $authString = ""

    # SHA256 hash the body up to the first $MaxBody characters
    $bodyHash = [string]::Empty
    if ($Body -and $Method -eq 'POST') {
        $sha256 = [Security.Cryptography.SHA256]::Create()
        $bodyToHash = if ($Body.Length -le $MaxBody) { $Body } else { $Body.Substring(0,$MaxBody) }
        $bodyBytes = [Text.Encoding]::ASCII.GetBytes($bodyToHash)
        $bodyHash = [Convert]::ToBase64String($sha256.ComputeHash($bodyBytes))
    }

    # Build the signature data
    $sigData = "$Method`thttps`t$($uri.Authority)`t$($uri.PathAndQuery)`t`t$bodyHash`t$authString"

    # Hash the timestamp using the client secret and then use that to
    # hash the signature data to get the signature for the auth header
    $tsHash = Get-HMACSHA256Hash $ClientSecret $unixTimestamp
    $signature = Get-HMACSHA256Hash $tsHash $sigData

    $hmacSignature = "";
    $headers = @{
        Authorization = "hmac ${ApiKey}:${hmacSignature}:${nonce}:${unixTimestamp}"
        Accept = $AcceptHeader
    }

    # Apparently Akamai doesn't support the "Expect: 100 Continue" header
    # and other implementations try to explicitly disable it using
    # [System.Net.ServicePointManager]::Expect100Continue = $false
    # However, none of the environments I tested (PS 5.1, 6, and 7)
    # actually sent that header by default for any HTTP verb.
    # It's plausible it was sent pre-5.1 or pre-.NET 4.7.1. But since
    # we don't support those, we don't have to worry about them.

    # build the call parameters
    $irmParams = @{
        Method = $Method
        Uri = $uri
        Headers = $headers
        ContentType = 'application/json'
        MaximumRedirection = 0
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $irmParams.Body = $Body
    }

    try {
        Invoke-RestMethod @irmParams @script:UseBasic
    } catch {
        # ignore 404 errors and just return $null
        # otherwise, let it through
        if ([Net.HttpStatusCode]::NotFound -eq $_.Exception.Response.StatusCode) {
            return $null
        } else { throw }
    }
}

function Get-CombellDnsRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DomainName,
        [string]$RecordType = $null,
        [string]$ApiKey,
        [string]$ApiSecret
    )

    # Docs @ https://api.combell.com/v2/documentation#tag/DNS-records/paths/~1dns~1{domainName}~1records/get
    # HTTP GET https://api.combell.com/v2/dns/{domainName}/records?type=$RecordType

    $requestPath = "dns/$DomainName/records";
    if ([string]::IsNullOrEmpty($RecordType) -eq $false) {
        $requestPath += "?type=$RecordType";
    }
    Write-Verbose "HTTP GET $requestPath";

    $response = Send-CombellHttpRequest $requestPath -Method GET -ApiKey $ApiKey -ApiSecret $ApiSecret;

    # TODO Print $response to output
    $response | Format-List;

    <#
    .SYNOPSIS
        Gets the DNS records of the specified domain name.
    #>
}
