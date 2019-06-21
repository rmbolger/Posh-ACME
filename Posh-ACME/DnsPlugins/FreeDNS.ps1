function Add-DnsTxtFreeDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$FDCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-FreeDNS @PSBoundParameters

    $domains = Get-FDOwnedDomains

    $domains | ForEach-Object {
        Write-Verbose "$($_.domain) = $($_.id)"
        $recs = Get-FDTxtRecords $_.id $_.domain
        $recs | ForEach-Object {
            Write-Verbose "    $($_.nameShort) = $($_.value)"
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to FreeDNS

    .DESCRIPTION
        Add a DNS TXT record to FreeDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtFreeDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtFreeDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$FDCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-FreeDNS @PSBoundParameters

    <#
    .SYNOPSIS
        Remove a DNS TXT record from FreeDNS

    .DESCRIPTION
        Remove a DNS TXT record from FreeDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtFreeDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtFreeDNS {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required

    .DESCRIPTION
        This provider does not require calling this function to save DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# http://freedns.afraid.org/faq/#17
# Inspiration from
# https://github.com/Neilpang/acme.sh/blob/master/dnsapi/dns_freedns.sh

function Connect-FreeDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$FDCred,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # no need to login again if we already have an authenticated session
    if ($script:FDSession) {
        Write-Debug "Using cached FreeDNS session"
        return
    }

    # get plain text versions of the pscredential we can work with
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $FDUsername = $FDCred.UserName
        $FDPassword = $FDCred.GetNetworkCredential().Password
    }

    # URI escape the credentials
    $userEscaped = [uri]::EscapeDataString($FDUsername)
    $passEscaped = [uri]::EscapeDataString($FDPassword)

    $irmArgs = @{
        Uri = 'https://freedns.afraid.org/zc.php?step=2'
        Method = 'Post'
        Body = "username=$userEscaped&password=$passEscaped&submit=Login&action=auth"
        SessionVariable = 'FDSession'
        ErrorAction = 'Stop'
    }

    try { Invoke-WebRequest @irmArgs @script:UseBasic | Out-Null }
    catch {
        # So PowerShell Core has an open issue that throws an exception on a 302 redirect
        # when the original location is HTTPS and the new location is HTTP.
        # https://github.com/PowerShell/PowerShell/issues/2896
        # For some reason, afraid.org is redirecting to HTTP after we auth over HTTPS and
        # is triggering this bug.
        # However, a successful login still generates the WebSession with the auth cookie
        # we care about. So we're just going to swallow the error on Core and go about our
        # if it looks like the login was successful.
        if ($FDSession.Cookies.Count -gt 0 -and 'Core' -eq $PSEdition) {
            Write-Debug "Got cookies on Core despite exception!"
        } else {
            throw
        }
    }

    # invalid logins still return HTTP 200 but they don't return any cookies
    # so we'll check for cookies as a success indicator rather than parsing the HTML output
    if ($FDSession.Cookies.Count -gt 0) {
        Write-Debug "FreeDNS authentication success"

        # If we try to use the existing WebRequestSession object as-is, PowerShell won't pass
        # the dns_cookie to the requests we're making later for some reason. It might be related
        # to the path associated with the cookie. As a workaround, we'll create a new session
        # and plug the cookie value into it with a super generic path which seems to work.

        # Create a new session object using the dns_cookie we got back
        $script:FDSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $FDSession.Cookies.GetCookies($irmArgs.Uri) | ForEach-Object {
            if ('dns_cookie' -eq $_.name) {
                Write-Debug "Saving dns_cookie value"
                $script:FDSession.Cookies.Add([Net.Cookie]::new($_.name, $_.value, '', 'freedns.afraid.org'))
            }
        }
    } else {
        throw "Error authenticating to FreeDNS. Check your credentials."
    }
}

function Get-FDOwnedDomains {
    [CmdletBinding()]
    param()

    $url = 'https://freedns.afraid.org/domain/'
    $reDomains = [regex]'(?smi)"2"><b>(?<domain>[-_.a-z0-9]+).+?(?:href=/subdomain/\?limit=)(?<id>\d+)>'

    # Possible to get this from /subdomain/ as well
    # $url = 'https://freedns.afraid.org/subdomain/'
    # $reDomains = [regex]'(?smi)<td>(?<domain>[-_.a-z0-9]+).+?(?:edit_domain_id=)(?<id>\d+)'

    # On non-premium accounts, FreeDNS occasionally returns a page prompting
    # to go premium rather than the requested page. This usually happens after
    # a period of inactivity and immediately requesting the page again returns
    # the correct response. So check and try again if necessary.

    Write-Debug "Querying Domains page"
    $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
    $domains = $reDomains.Matches($response.Content)

    # retry once on failure
    if ($domains.Count -eq 0) {
        $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
        $domains = $reDomains.Matches($response.Content)
    }

    if ($domains.Count -eq 0) {
        throw "Unable to find any owned domains. Please add at least one."
    } else {
        Write-Debug "$($domains.Count) domain matches found."
    }

    $domains | ForEach-Object {
        [pscustomobject]@{domain=$_.Groups['domain'].value; id=$_.Groups['id'].value}
    }

}

function Get-FDTxtRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainID,
        [Parameter(Mandatory)]
        [string]$DomainName
    )

    $url = "https://freedns.afraid.org/subdomain/?limit=$DomainID"
    #$reRecs = [regex]'(?smi)<a href=edit.php\?data_id=(?<id>\d+)>(?<name>[-_.a-z0-9]+)</a>.*?>TXT</td><td bgcolor=#eeeeee>&quot;(?<value>.+?)&quot;</td>'
    $reRecs = [regex]'(?smi)<tr><td bgcolor=#eeeeee.+?(?:data_id=)(?<id>\d+)>(?<name>[-_.a-z0-9]+)</a>.+?(?:<td bgcolor=#eeeeee>)(?<type>\w+)(?:</td><td bgcolor=#eeeeee>)(?<value>.+?)</td>'

    # On non-premium accounts, FreeDNS occasionally returns a page prompting
    # to go premium rather than the requested page. This usually happens after
    # a period of inactivity and immediately requesting the page again returns
    # the correct response. So check and try again if necessary.

    Write-Debug "Querying records for domain $DomainID"
    $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
    $recs = $reRecs.Matches($response.Content)

    # retry once on failure
    if ($recs.Count -eq 0) {
        $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
        $recs = $reRecs.Matches($response.Content)
    }

    $recs = $recs | Where-Object { 'TXT' -eq $_.Groups['type'].value }
    Write-Debug "$($recs.Count) TXT records found."

    $recs | ForEach-Object {
        [pscustomobject]@{
            name  = $_.Groups['name'].value
            nameShort = $_.Groups['name'].value.Replace(".$DomainName",'')
            id    = $_.Groups['id'].value
            value = $_.Groups['value'].value.Trim("&quot;")
        }
    }

}
