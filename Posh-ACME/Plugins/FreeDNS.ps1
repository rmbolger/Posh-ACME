function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$FDCredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-FreeDNS @PSBoundParameters

    $zone = Find-FDZone $RecordName
    Write-Verbose "Found owned domain $($zone.domain) ($($zone.id))"

    $rec = Get-FDTxtRecords $zone.id $zone.domain $RecordName $TxtValue
    $recShort = ($RecordName -ireplace [regex]::Escape($zone.domain), [string]::Empty).TrimEnd('.')

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # add the new record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        # type=TXT&domain_id=$domain_id&subdomain=$subdomain&address=%22$value%22&send=Save%21
        $iwrArgs = @{
            Uri = 'https://freedns.afraid.org/subdomain/save.php?step=2'
            Method = 'Post'
            Body = @{
                type = 'TXT'
                domain_id = $zone.id
                subdomain = $recShort
                address = "`"$TxtValue`""
                send = 'Save!'
            }
            WebSession = $script:FDSession
            ErrorAction = 'Stop'
        }

        $response = Invoke-WebRequest @iwrArgs @script:UseBasic

        # success: Subdomains page with no confirmation, but TxtValue should be in the table now
        # duplicate: "You already have another already existent <blah> record."
        # underscore, not owned: "Creation of records beginning with '_' are presently restricted to the domain owner only by default - this is temporary (2016-02-10) please contact me if you need access."
        # captcha: "The security code was incorrect, please try again."

        # Check for the errors we know about. For now, we'll assume anything else is a success.
        if ($response.Content -like "*Creation of records beginning with '_' are presently restricted to the domain owner*") {
            throw "FreeDNS does not allow creating records beginning with '_' unless you are the domain owner."
        } elseif ($response.Content -like '*security code was incorrect*') {
            throw "FreeDNS requires solving a CAPTCHA to add records unless you are the domain owner or have a premium account. Upgrade your account to premium or use one of your own domains."
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

    .PARAMETER FDCredential
        Username and password for FreeDNS. This PSCredential option can only be used from Windows or any OS running PowerShell 6.2 or later.

    .PARAMETER FDUsername
        Username for FreeDNS. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER FDPassword
        Password for FreeDNS. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' -FDCredential (Get-Credential)

        Adds a TXT record using after providing credentials in a prompt.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txtvalue' -FDUsername 'myusername' -FDPassword 'mypassword'

        Adds a TXT record using plain text credentials.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$FDCredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$FDPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-FreeDNS @PSBoundParameters

    $zone = Find-FDZone $RecordName
    Write-Verbose "Found owned domain $($zone.domain) ($($zone.id))"

    $rec = Get-FDTxtRecords $zone.id $zone.domain $RecordName $TxtValue

    if ($rec) {
        # remove the record
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"

        $iwrArgs = @{
            Uri = "https://freedns.afraid.org/subdomain/delete2.php?data_id%5B%5D=$($rec.id)&submit=delete+selected"
            Method = 'Get'
            WebSession = $script:FDSession
            ErrorAction = 'Stop'
        }

        Invoke-WebRequest @iwrArgs @script:UseBasic | Out-Null
        # No error is generated when trying to delete a record that doesn't exist.
        # No error is generated when trying to delete a record that is not yours.

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from FreeDNS

    .DESCRIPTION
        Remove a DNS TXT record from FreeDNS

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER FDCredential
        Username and password for FreeDNS. This PSCredential option can only be used from Windows or any OS running PowerShell 6.2 or later.

    .PARAMETER FDUsername
        Username for FreeDNS. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER FDPassword
        Password for FreeDNS. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txtvalue' -FDCredential (Get-Credential)

        Removes a TXT record using after providing credentials in a prompt.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txtvalue' -FDUsername 'myusername' -FDPassword 'mypassword'

        Removes a TXT record using plain text credentials.
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
# Adapted from
# https://github.com/Neilpang/acme.sh/blob/master/dnsapi/dns_freedns.sh

function Connect-FreeDNS {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$FDCredential,
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
        $FDUsername = $FDCredential.UserName
        $FDPassword = $FDCredential.GetNetworkCredential().Password
    }

    # URI escape the credentials
    $userEscaped = [uri]::EscapeDataString($FDUsername)
    $passEscaped = [uri]::EscapeDataString($FDPassword)

    $iwrArgs = @{
        Uri = 'https://freedns.afraid.org/zc.php?step=2'
        Method = 'Post'
        Body = "username=$userEscaped&password=$passEscaped&submit=Login&action=auth"
        SessionVariable = 'FDSession'
        ErrorAction = 'Stop'
    }

    try { Invoke-WebRequest @iwrArgs @script:UseBasic | Out-Null }
    catch {
        # PowerShell Core has an open issue that throws an exception on a 302 redirect
        # when the original location is HTTPS and the new location is HTTP.
        # https://github.com/PowerShell/PowerShell/issues/2896
        # For some reason, afraid.org is redirecting to HTTP after we auth over HTTPS and
        # is triggering this bug.
        # However, a successful login still generates the WebSession with the auth cookie
        # we care about. So we're just going to swallow the error on Core continue if it
        # looks like the login was successful.
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
        $FDSession.Cookies.GetCookies($iwrArgs.Uri) | ForEach-Object {
            if ('dns_cookie' -eq $_.name) {
                Write-Debug "Saving dns_cookie value"
                $script:FDSession.Cookies.Add([Net.Cookie]::new($_.name, $_.value, '', 'freedns.afraid.org'))
            }
        }
    } else {
        throw "Error authenticating to FreeDNS. Check your credentials."
    }
}

function Get-FDDomains {
    [CmdletBinding()]
    param()

    # It's possible to limit these zones to only "owned" domains from the Domains page. But it's possible
    # people may be adding non-underscore TXT records to unowned domains. So we need to include those as well.
    # $url = 'https://freedns.afraid.org/domain/'
    # $reDomains = [regex]'(?smi)"2"><b>(?<domain>[-_.a-z0-9]+).+?(?:href=/subdomain/\?limit=)(?<id>\d+)>'

    # It's possible to get this data from /subdomain/ as well
    $url = 'https://freedns.afraid.org/subdomain/'
    $reDomains = [regex]'(?smi)<td>(?<domain>[-_.a-z0-9]+).+?(?:edit_domain_id=)(?<id>\d+)'

    # On non-premium accounts, FreeDNS occasionally returns a page prompting
    # to go premium rather than the requested page. This usually happens after
    # a period of inactivity and immediately requesting the page again returns
    # the correct response. So check and try again if necessary.

    Write-Debug "Querying Subdomains page"
    $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
    $domains = $reDomains.Matches($response.Content)

    # retry once on failure
    if ($domains.Count -eq 0) {
        $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
        $domains = $reDomains.Matches($response.Content)
    }

    if ($domains.Count -eq 0) {
        throw "Unable to find any domains. You must first add at least one record to the domain you are trying to use."
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
        [string]$DomainName,
        [string]$RecordName,
        [string]$TxtValue
    )

    $url = "https://freedns.afraid.org/subdomain/?limit=$DomainID"
    $reRecs = [regex]'(?smi)<tr><td bgcolor=#eeeeee.+?(?:data_id=)(?<id>\d+)>(?<name>[-_.a-z0-9]+)</a>.+?(?:<td bgcolor=#eeeeee>)(?<type>\w+)(?:</td><td bgcolor=#eeeeee>)(?<value>.+?)</td>'

    # On non-premium accounts, FreeDNS occasionally returns a page prompting
    # to go premium rather than the requested page. This usually happens after
    # a period of inactivity and immediately requesting the page again returns
    # the correct response. So check and try again if necessary.

    Write-Debug "Querying records for domain $DomainID"
    $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
    $recMatches = $reRecs.Matches($response.Content)

    # retry once on failure
    if ($recMatches.Count -eq 0) {
        $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
        $recMatches = $reRecs.Matches($response.Content)
    }

    # filter out non-TXT records
    $recMatches = $recMatches | Where-Object { 'TXT' -eq $_.Groups['type'].value }
    Write-Debug "$($recMatches.Count) TXT records found."

    # filter by record name if specified
    if (-not [string]::IsNullOrWhiteSpace($RecordName)) {
        $recMatches = $recMatches | Where-Object { $RecordName -eq $_.Groups['name'].value }
    }

    # The Subdomains page appears to truncate the record values if they are longer than
    # a certain threshold (~20 characters). It truncates the text and adds a "..." at the end.
    # Unfortunately, all of our ACME challenge records are going to exceed that length. So in
    # order to get the full value, we have to fetch the edit page for that record which has
    # the complete value in a text box.

    # first flatten the current results so it's easier to modify
    $recs = $recMatches | ForEach-Object {
        [pscustomobject]@{
            name  = $_.Groups['name'].value
            nameShort = $_.Groups['name'].value.Replace(".$DomainName",'')
            id    = $_.Groups['id'].value
            value = $_.Groups['value'].value.Trim("&quot;")
        }
    }

    foreach ($rec in $recs) {
        # skip anything that hasn't been truncated
        if (-not $rec.value.EndsWith('...')) { continue }
        $rec.value = Get-FDTxtRecordValue $rec.id
        Write-Debug "Updated $($rec.nameshort) value to $($rec.value)"
    }

    # filter by txt value if specified
    if (-not [string]::IsNullOrWhiteSpace($TxtValue)) {
        $recs = $recs | Where-Object { $TxtValue -eq $_.value }
    }

    $recs
}

function Find-FDZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:FDRecordZones) { $script:FDRecordZones = @{} }

    # check for the record in the cache
    if ($script:FDRecordZones.ContainsKey($RecordName)) {
        return $script:FDRecordZones.$RecordName
    }

    # grab the set of owned domains for this account
    $domains = Get-FDDomains

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        if ($zoneTest -in $domains.domain) {
            $script:FDRecordZones.$RecordName = $domains | Where-Object { $zoneTest -eq $_.domain }
            return $script:FDRecordZones.$RecordName
        }
    }

    throw "No zone found for $RecordName"
}

function Get-FDTxtRecordValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordID
    )

    $url = "https://freedns.afraid.org/subdomain/edit.php?data_id=$RecordID"
    $reTxtValue = [regex]'"&quot;(?<value>.*)&quot;"'

    # On non-premium accounts, FreeDNS occasionally returns a page prompting
    # to go premium rather than the requested page. This usually happens after
    # a period of inactivity and immediately requesting the page again returns
    # the correct response. So check and try again if necessary.

    Write-Debug "Querying Record $RecordID page"
    $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
    $valMatches = $reTxtValue.Matches($response.Content)

    # retry once on failure
    if ($valMatches.Count -eq 0) {
        $response = Invoke-WebRequest $url -WebSession $script:FDSession @script:UseBasic
        $valMatches = $reTxtValue.Matches($response.Content)
    }

    if ($valMatches.Count -eq 0) {
        throw "Unable to parse the TXT record value."
    }

    # there should be only one result
    return $valMatches[0].Groups['value'].value
}
