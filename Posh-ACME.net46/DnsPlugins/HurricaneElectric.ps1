function Add-DnsTxtHurricaneElectric {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$HECredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$HEUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$HEPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-HurricaneElectric @PSBoundParameters

    $zone = Find-HEZone $RecordName
    Write-Verbose "Found domain $($zone.domain) ($($zone.id))"

    $rec = Get-HETxtRecord $zone.id $RecordName $TxtValue

    if ($rec) {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
    } else {
        # add the new record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

        # build the form body
        $addBody = "account=&menu=edit_zone&Type=TXT&hosted_dns_zoneid=$($zone.id)&hosted_dns_recordid=&hosted_dns_editzone=1&Priority=&Name=$RecordName&Content=$TxtValue&TTL=300&hosted_dns_editrecord=Submit"
        $iwrArgs = @{
            Uri = 'https://dns.he.net/'
            Method = 'Post'
            Body = $addBody
            WebSession = $script:HESession
            ErrorAction = 'Stop'
        }

        try {
            $response = Invoke-WebRequest @iwrArgs @script:UseBasic
        } catch { throw }

        $reStatus = '"dns_status"[^>]+>(?<status>[^<]+)<'

        if ($response.Content -match $reStatus) {
            $status = $matches['status']
            if ($status -notlike 'Successfully added new record*') {
                Write-Warning "Unexpected result status while adding record: $status"
            }
        } else {
            Write-Debug "No dns_status div found after add."
        }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Hurricane Electric

    .DESCRIPTION
        Add a DNS TXT record to Hurricane Electric

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HECredential
        Username and password for Hurricane Electric. This PSCredential option can only be used from Windows or any OS running PowerShell 6.2 or later.

    .PARAMETER HEUsername
        Username for Hurricane Electric. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER HEPassword
        Password for Hurricane Electric. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtHurricaneElectric '_acme-challenge.example.com' 'txtvalue' -HECredential (Get-Credential)

        Adds a TXT record using after providing credentials in a prompt.

    .EXAMPLE
        Add-DnsTxtHurricaneElectric '_acme-challenge.example.com' 'txtvalue' -HEUsername 'myusername' -HEPassword 'mypassword'

        Adds a TXT record using plain text credentials.
    #>
}

function Remove-DnsTxtHurricaneElectric {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$HECredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$HEUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$HEPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Connect-HurricaneElectric @PSBoundParameters

    $zone = Find-HEZone $RecordName
    Write-Verbose "Found domain $($zone.domain) ($($zone.id))"

    $rec = Get-HETxtRecord $zone.id $RecordName $TxtValue

    if ($rec) {
        # remove the record
        Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"

        # build the form body
        $delBody = "menu=edit_zone&hosted_dns_zoneid=$($zone.id)&hosted_dns_recordid=$($rec.id)&hosted_dns_editzone=1&hosted_dns_delrecord=1&hosted_dns_delconfirm=delete"
        $iwrArgs = @{
            Uri = 'https://dns.he.net/'
            Method = 'Post'
            Body = $delBody
            WebSession = $script:HESession
            ErrorAction = 'Stop'
        }

        try {
            $response = Invoke-WebRequest @iwrArgs @script:UseBasic
        } catch { throw }

        $reStatus = '"dns_status"[^>]+>(?<status>[^<]+)<'

        if ($response.Content -match $reStatus) {
            $status = $matches['status']
            if ($status -ne 'Successfully removed record.') {
                Write-Warning "Unexpected result status while removing record: $status"
            }
        } else {
            Write-Debug "No dns_status div found after add."
        }

    } else {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Hurricane Electric

    .DESCRIPTION
        Remove a DNS TXT record from Hurricane Electric

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER HECredential
        Username and password for Hurricane Electric. This PSCredential option can only be used from Windows or any OS running PowerShell 6.2 or later.

    .PARAMETER HEUsername
        Username for Hurricane Electric. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER HEPassword
        Password for Hurricane Electric. This should be used from non-Windows OSes running PowerShell 6.0-6.1.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtHurricaneElectric '_acme-challenge.example.com' 'txtvalue' -HECredential (Get-Credential)

        Removes a TXT record using after providing credentials in a prompt.

    .EXAMPLE
        Remove-DnsTxtHurricaneElectric '_acme-challenge.example.com' 'txtvalue' -HEUsername 'myusername' -HEPassword 'mypassword'

        Removes a TXT record using plain text credentials.
    #>
}

function Save-DnsTxtHurricaneElectric {
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

# Adapted from
# https://github.com/Neilpang/acme.sh/blob/master/dnsapi/dns_he.sh
# Web scraping is obviously brittle and can easily break if the site owner changes their markup.
# But without a well-defined API, this is the only option for automated record manipulation.

function Connect-HurricaneElectric {
    [CmdletBinding(DefaultParameterSetName='Secure')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword','')]
    param(
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [pscredential]$HECredential,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$HEUsername,
        [Parameter(ParameterSetName='Insecure',Mandatory)]
        [string]$HEPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # no need to login again if we already have an authenticated session
    if ($script:HESession) {
        Write-Debug "Using cached HE.net session"
        return
    }

    # get plain text versions of the pscredential we can work with
    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $HEUsername = $HECredential.UserName
        $HEPassword = $HECredential.GetNetworkCredential().Password
    }

    # URI escape the credentials
    $userEscaped = [uri]::EscapeDataString($HEUsername)
    $passEscaped = [uri]::EscapeDataString($HEPassword)

    $siteRoot = 'https://dns.he.net/'

    $loginParams = @{
        Uri = $siteRoot
        Method = 'Post'
        Body = "email=$userEscaped&pass=$passEscaped"
        ErrorAction = 'Stop'
    }

    try {
        # Do an initial GET to establish the session cookie
        Invoke-WebRequest $siteRoot -SessionVariable 'HESession' @script:UseBasic -EA Stop | Out-Null

        # try to login
        $response = Invoke-WebRequest @loginParams -WebSession $HESession @script:UseBasic
    }
    catch { throw }

    if ($response.Content -like '*>Incorrect<*') {
        throw "Invalid he.net login credentials. Please check username and password."
    }

    # save the session variable for later
    $script:HESession = $HESession
}

function Get-HEDomains {
    [CmdletBinding()]
    param()

    $url = 'https://dns.he.net/'
    $reDomains = [regex]'onclick="delete_dom\(this\);" name="(?<domain>[-_.a-z0-9]+)" value="(?<id>\d+)"'

    Write-Debug "Querying domains page"
    try {
        $response = Invoke-WebRequest $url -WebSession $script:HESession @script:UseBasic -EA Stop
    } catch { throw }
    $domains = $reDomains.Matches($response.Content)

    if ($domains.Count -eq 0) {
        throw "Unable to find any domains."
    } else {
        Write-Debug "$($domains.Count) domain matches found."
    }

    $domains | ForEach-Object {
        [pscustomobject]@{domain=$_.Groups['domain'].value; id=$_.Groups['id'].value}
    }
}

function Get-HETxtRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DomainID,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue
    )

    $url = "https://dns.he.net/?hosted_dns_zoneid=$DomainID&menu=edit_zone&hosted_dns_editzone"
    $reVal = [regex]'data="&quot;(?<val>[^&]+)&quot;'
    $reName = [regex]'deleteRecord\(''(?<id>\d+)'',''(?<fqdn>[-_.a-z0-9]+)'''

    Write-Debug "Querying records for domain $DomainID"
    $response = Invoke-WebRequest $url -WebSession $script:HESession @script:UseBasic

    # split the content by line breaks so we can loop through it looking for the data
    $lines = $response.Content -split "`r?`n"

    for ($i=0; $i -lt $lines.Count; $i++) {

        if ($lines[$i] -like '*rrlabel TXT*') {
            # the next line should have the record value
            if ($lines[$i+1] -notmatch $reVal) {
                Write-Debug "Failed to parse TXT record value from line following 'rrlabel TXT'"
                continue
            }
            $recVal = $matches['val']

            # the line after that should have the record name and ID
            if ($lines[$i+2] -notmatch $reName) {
                Write-Debug "Failed to parse TXT record name/ID from line following 'rrlabel TXT'"
                continue
            }
            $recFQDN = $matches['fqdn']
            $recID = $matches['id']

            # send back a match if we found it
            if ($recFQDN -eq $RecordName -and $recVal -eq $TxtValue) {
                [pscustomobject]@{
                    fqdn = $recFQDN
                    id = $recID
                    value = $recVal
                }
                return
            }

            $i += 2
        }
    }
}

function Find-HEZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:HERecordZones) { $script:HERecordZones = @{} }

    # check for the record in the cache
    if ($script:HERecordZones.ContainsKey($RecordName)) {
        return $script:HERecordZones.$RecordName
    }

    # grab the set of owned domains for this account
    $domains = Get-HEDomains

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zoneTest"
        if ($zoneTest -in $domains.domain) {
            $script:HERecordZones.$RecordName = $domains | Where-Object { $zoneTest -eq $_.domain }
            return $script:HERecordZones.$RecordName
        }
    }

    throw "No zone found for $RecordName"
}
