function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$EasynameCredential,
        $ExtraParams
    )

    $zoneID,$zoneName = Find-EasynameDomain $RecordName $EasynameCredential
    if (-not $zoneID -or -not $zoneName) {
        throw "No domain match found for record $RecordName"
    }

    if (Get-EasynameTxtRecord $RecordName $TxtValue $zoneID $EasynameCredential) {
        # nothing to do
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."

    } else {

        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        $recShort = $RecordName -ireplace "\.?$([regex]::Escape($zoneName.TrimEnd('.')))$",''

        $addParams = @{
            Uri = "https://my.easyname.com/en/domain/dns/create/domain/$zoneID"
            Method = 'POST'
            Body = @{
                id       = [string]::Empty
                name     = $recShort
                type     = 'TXT'
                content  = $TxtValue
                priority = '0'
                ttl      = '300'
            }
            Credential = $EasynameCredential
        }
        $src = Invoke-EasynameRequest @addParams

        if ($src -notlike '*feedback-message--success*') {
            # Try to parse the error message from the response
            if ($src -match '(?smi)class="feedback-message__text">(?<msg>[^<]+)<') {
                throw "Easyname error: $([Net.WebUtility]::HtmlDecode($matches.msg))"
            } else {
                throw "Unknown Easyname error adding record"
            }
        }

    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Easyname.com

    .DESCRIPTION
        Description for Easyname.com

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER EasynameCredential
        Email and password for the Easyname.com account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' (Get-Credential)

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [pscredential]$EasynameCredential,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zoneID,$zoneName = Find-EasynameDomain $RecordName $EasynameCredential
    if (-not $zoneID -or -not $zoneName) {
        throw "No domain match found for record $RecordName"
    }

    if ($rec = Get-EasynameTxtRecord $RecordName $TxtValue $zoneID $EasynameCredential) {

        Write-Verbose "Deleting TXT record for $RecordName with value $TxtValue"

        $delParams = @{
            Uri = "https://my.easyname.com/en/domain/dns/delete/domain/$zoneID/id/$($rec.ID)/confirm/1"
            Method = 'POST'
            Credential = $EasynameCredential
        }
        $src = Invoke-EasynameRequest @delParams

        if ($src -notlike '*feedback-message--success*') {
            # Try to parse the error message from the response
            if ($src -match '(?smi)class="feedback-message__text">(?<msg>[^<]+)<') {
                throw "Easyname error: $([Net.WebUtility]::HtmlDecode($matches.msg))"
            } else {
                throw "Unknown Easyname error removing record"
            }
        }

    } else {
        # nothing to do
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Easyname.com

    .DESCRIPTION
        Description for Easyname.com

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER EasynameCredential
        Email and password for the Easyname.com account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' (Get-Credential)

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

function New-EasynameWebSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [pscredential]$EasynameCredential
    )

    # make an unauthenticated request to create a session object
    $loginUrl = 'https://my.easyname.com/en/login'
    Write-Debug "GET $loginUrl"
    $null = Invoke-WebRequest $loginUrl -SessionVariable session @script:UseBasic -Verbose:$false

    # grab the CSRF token from the returned cookies and add it to the session headers
    $cookies = $session.Cookies.GetCookies($loginUrl)
    $session.Headers["X-CSRF-TOKEN"] = $cookies['CSRF-TOKEN'].Value

    # attempt to login using the specified credentials (which is oddly a JSON endpoint)
    $loginParams = @{
        Uri = 'https://my.easyname.com/en/authentication-api/login'
        Method = 'POST'
        Body = @{
            emailAddress = $EasynameCredential.UserName
            password = $EasynameCredential.GetNetworkCredential().Password
        } | ConvertTo-Json
        ContentType = 'application/json'
        WebSession = $session
        ErrorAction = 'Stop'
        Verbose = $false
    }
    Write-Debug "Attempting to login as $($EasynameCredential.UserName)"
    Write-Debug "POST $($loginParams.Uri)"
    $response = Invoke-RestMethod @loginParams @script:UseBasic

    if ($response.userId) {
        $script:EasynameSession = $session
    }
    else { throw "Unexpected Easyname login response. No user ID found." }
}

function Invoke-EasynameRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Uri,
        [string]$Method = 'GET',
        [hashtable]$Body,
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    # This is a wrapper for web-scraping requests to the Easyname.com website
    # so we can check for session expiration and re-login/re-try if necessary.

    # create a session if it doesn't exist
    if (-not $script:EasynameSession) {
        New-EasynameWebSession $Credential
    }

    # build the param set
    $reqParams = @{
        Uri = $Uri
        Method = $Method
        WebSession = $script:EasynameSession
        ErrorAction = 'Stop'
        Verbose = $false
    }
    Write-Debug "$Method $Uri"

    # add the body if there is one
    if ($Body) {
        $reqParams.Body = $Body
        Write-Debug "Body:`n$($Body | ConvertTo-Json)"
    }

    # send the request
    try { $response = Invoke-WebRequest @reqParams @script:UseBasic }
    catch { throw }

    # check for a login page response which means our session is either invalid
    # or expired
    if ($response.Content -like '*id="react-auth-page"*') {
        # create a new session and try again
        Write-Debug "Response contains login page, attempting to re-login and try again."
        New-EasynameWebSession $Credential
        $reqParams.WebSession = $script:EasynameSession
        try { $response = Invoke-WebRequest @reqParams @script:UseBasic }
        catch { throw }
    }
    else { return $response.Content }

    # error if we get a login page response again
    if ($response.Content -like '*id="react-auth-page"*') {
        throw "Response contains login page. Easyname authentication failing."
    }
    else { return $response.Content }
}

Function Get-EasynameDomains {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [pscredential]$Credential
    )

    # The REST API technically supports getting this domain/ID data. But since
    # we can't do everything via the API (yet?), it doesn't make sense right
    # now to make the users provide API credentials as well as their regular
    # login credentials just to avoid web scraping for one thing.

    $src = Invoke-EasynameRequest 'https://my.easyname.com/domains/' -Cred $Credential

    # Parse the domain/ID values from the HTML source.
    # Right now, this assumes all domains on the account a returned and may
    # break if the UI starts paging once you reach a certain domain count.
    $reDomains = [regex]'(?smi)<span class="domainname">(\S+)</span>.*?<a href="/\w+/domain/dns/index/domain/(\d+)">DNS'
    $reDomains.Matches($src) | ForEach-Object {
        [pscustomobject]@{
            id = $_.Groups[2].Value
            domain = $_.Groups[1].Value
        }
    }
}

function Find-EasynameDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [pscredential]$Credential
    )

    # setup a module variable to cache the record to domain ID mapping
    if (!$script:EasynameRecordZones) { $script:EasynameRecordZones = @{} }

    # check for the record in the cache
    if ($script:EasynameRecordZones.ContainsKey($RecordName)) {
        return $script:EasynameRecordZones.$RecordName
    }

    Write-Debug "Searching for domains that match $RecordName"

    $domains = Get-EasynameDomains $Credential

    # find the domain that matches the record
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        if ($zoneTest -in $domains.domain) {
            $id = ($domains |
                Where-Object { $zoneTest -eq $_.domain } |
                Select-Object -First 1).id
            $script:EasynameRecordZones.$RecordName = $id,$zoneTest
            Write-Debug "Found record match in domain $zoneTest with id $id"
            return $script:EasynameRecordZones.$RecordName
        }
    }
}

function Get-EasynameTxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position=2)]
        [string]$ZoneID,
        [Parameter(Mandatory,Position=3)]
        [pscredential]$Credential
    )

    $src = Invoke-EasynameRequest "https://my.easyname.com/en/domain/dns/index/domain/$ZoneID" -Cred $Credential

    # Parse the specific record ID from the source if it exists
    $recNameEscaped = [regex]::Escape($RecordName)
    $reTemplate = '(?smi)class="entity__name">\s*{0}\s*</td>.*?class="entity__type">.*?TXT.*?</abbr>.*?class="entity__content">.*?{1}</code>\s*</td>.*?href="https://my.easyname.com/\w+/domain/dns/edit/domain/{2}/id/(?<recID>\d+)"'
    $reRecord = [regex]($reTemplate -f $recNameEscaped,$TxtValue,$ZoneID)

    if ($src -match $reRecord) {
        Write-Debug "Found record with id $($matches.recID)"
        [pscustomobject]@{
            RecordName = $RecordName
            TxtValue = $TxtValue
            ID = $matches.recID
        }
    }
}


################################
# Begin: Experimental REST API #
################################

<#
    Easyname.com does have a REST API, but it's extremely limited as of April
    2021. It can basically only provide the domain ID and no DNS record
    manipulation. But here's the URL for future reference in case it gets better.

    https://api-docs.easyname.com/
#>

# Function Get-StringHash {
#     param
#     (
#         [String] $String,
#         $HashName = "MD5"
#     )
#     # https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/generating-md5-hashes-from-text
#     $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
#     $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
#     $StringBuilder = New-Object System.Text.StringBuilder

#     $algorithm.ComputeHash($bytes) |
#     ForEach-Object {
#         $null = $StringBuilder.Append($_.ToString("x2"))
#     }

#     $StringBuilder.ToString()
# }

# Function Get-XUserAuthenticationHeader {
#     [regex]$pattern = "%s"
#     $AuthenticationSalt = $pattern.Replace($EasynameAuthenticationSalt, $EasynameUserId, 1)
#     $AuthenticationSalt = $pattern.Replace($AuthenticationSalt, $EasynameUserEmail, 1)
#     [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-StringHash -String $AuthenticationSalt))
# }

# Function Get-EasynameDomainsRestfull {
#     [CmdletBinding()]

#     param (
#         [Parameter(Mandatory)]
#         [String]$EasynameUserEmail,
#         [Parameter(Mandatory)]
#         [String]$EasynameUserId,
#         [Parameter(Mandatory)]
#         [String]$EasynameAuthenticationSalt,
#         [Parameter(Mandatory)]
#         [String]$EasynameAPIKey,
#         [Parameter(ValueFromRemainingArguments)]
#         $ExtraParams
#     )
#     <#
#     .SYNOPSIS
#     Get a List of available Domains using the Easyname RestAPI

#     .EXAMPLE
#     $pArgs = @{EasynameUserId = '12345';
#                EasynameUserEmail = 'user@example.com';
#                EasynameAPIKey = 'APIKey12345';
#                EasynameAuthenticationSalt = '12345%abcd%s6789';
#                EasynameSigningSalt = 'sde7jk3FrHN43kCYEP2' }

#     $json = Get-EasynameDomainsRestfull | fl
#     $json.data

#     ...
#     id                     : 1234567
#     domain                 : example.com
#     domainIdn              : example.com
#     registrantContact      : 990099
#     adminContact           : 990099
#     techContact            : 990099
#     zoneContact            : 990099
#     autoRenew              : True
#     transferAllowed        : False
#     isTransferAwayPossible : True
#     trustee                : False
#     purchased              : 1970-01-01 00:00:00
#     expire                 : 2099-12-31 00:00:00
#     renewal                : 2099-12-31 00:00:00
#     authcode               : SecretAuthCodeHere
#     lastAuthcodeUpdate     : 1970-01-01 09:28:49
#     ...

#     .NOTES
#     Showcase using the Easyname Rest API to retrieve the list of Available Domains.

#     See the Notes in the corresponding Plugin Guide.
#     #>

#     $Params = @{
#         "URI"     = 'https://api.easyname.com/domain/'
#         "Method"  = 'GET'
#         "Headers" = @{
#             "Content-Type"          = 'application/json'
#             "X-User-ApiKey"         = $EasynameAPIKey
#             "X-User-Authentication" = Get-XUserAuthenticationHeader
#         }
#     }

#     $rest_response = Invoke-RestMethod @Params
#     return $rest_response
# }

##############################
# End: Experimental REST API #
##############################
