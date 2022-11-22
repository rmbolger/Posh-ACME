function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$KasUsername,
        [Parameter(ParameterSetName='plain',Mandatory,Position=2)]
        [securestring]$KasPwd,
        [Parameter(ParameterSetName='sha1',Mandatory,Position=2)]
        [securestring]$KasPwdHash,
        [Parameter(ParameterSetName='session',Mandatory,Position=2)]
        [securestring]$KasSession,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get effective KAS login data from parameter sets
    $loginData = Get-KasLoginDataFromParameters $PSCmdlet.ParameterSetName $KasUsername $KasPwd $KasPwdHash $KasSession

    # load current DNS settings from KAS API
    $settingsObj = Get-KASDNSSettings $loginData $RecordName

    # remove zone from record name
    $recNameWithoutZone = ($RecordName -ireplace [regex]::Escape($settingsObj.zone), [string]::Empty).TrimEnd('.')

    # search for existing DNS settings for the record
    $existingSettingsItem = Find-KASDNSSettingsItemInList $settingsObj.dnsSettings $recNameWithoutZone $TxtValue
    if ($existingSettingsItem) {
        Write-Verbose "Record $RecordName already contains $TxtValue. Nothing to do."
        return
    }

    # get zone_host for adding
    if ($settingsObj.zone.EndsWith(".")) {
        $zoneHost = $settingsObj.zone
    } else {
        $zoneHost = $settingsObj.zone + "."
    }

    # create DNS settings entry
    $addDnsSettingsParameters = @{
        'zone_host'=$zoneHost
        'record_type'='TXT'
        'record_name'=$recNameWithoutZone
        'record_data'=$TxtValue
        'record_aux'='0'
    }
    $kasAPIResponse = Invoke-KasApiAction $loginData 'add_dns_settings' $addDnsSettingsParameters

    Write-Debug $kasAPIResponse.OuterXml

    <#
    .SYNOPSIS
        Add a DNS TXT record to All-Inkl.com KAS

    .DESCRIPTION
        Uses the All-Inkl.com KAS API to add a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER KasUsername
        The KAS authentication user

    .PARAMETER KasPwd
        The password for your All-Inkl KAS account.

    .PARAMETER KasPwdHash
        The sha1 hash of the password for your All-Inkl KAS account.

    .PARAMETER KasSession
        The session id of an open session on the KAS API. Use this parameter if you want to handle authentication on your own.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -KasUsername 'userName' -KasPwd $pass

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
        [string]$KasUsername,
        [Parameter(ParameterSetName='plain',Mandatory,Position=2)]
        [securestring]$KasPwd,
        [Parameter(ParameterSetName='sha1',Mandatory,Position=2)]
        [securestring]$KasPwdHash,
        [Parameter(ParameterSetName='session',Mandatory,Position=2)]
        [securestring]$KasSession,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get effective KAS login data from parameter sets
    $loginData = Get-KasLoginDataFromParameters $PSCmdlet.ParameterSetName $KasUsername $KasPwd $KasPwdHash $KasSession

    # load current DNS settings from KAS API
    $settingsObj = Get-KASDNSSettings $loginData $RecordName

    # remove zone from record name
    $recNameWithoutZone = ($RecordName -ireplace [regex]::Escape($settingsObj.zone), [string]::Empty).TrimEnd('.')

    # search for existing DNS settings for the record
    $existingSettingsItem = Find-KASDNSSettingsItemInList $settingsObj.dnsSettings $recNameWithoutZone $TxtValue
    if ((-not $existingSettingsItem) -or (-not $existingSettingsItem.Node)) {
        Write-Verbose "Record $RecordName with value $TxtValue not found. Nothing to do."
        return
    }

    $recordIdElement = Select-XmlFromKASResult $existingSettingsItem.Node ".//item[contains(key, 'record_id')]/value"
    if ((-not $recordIdElement) -or (-not $recordIdElement.Node)) {
        throw "Couldn't read record id for $RecordName"
    }

    # create DNS settings entry
    $removeDnsSettingsParameters = @{
        'record_id'=$recordIdElement.Node.InnerText
    }
    $kasAPIResponse = Invoke-KasApiAction $loginData 'delete_dns_settings' $removeDnsSettingsParameters

    Write-Debug $kasAPIResponse.OuterXml

    <#
    .SYNOPSIS
        Remove a DNS TXT record from All-Inkl.com KAS

    .DESCRIPTION
        Uses the All-Inkl.com KAS API to remove the DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER KasUsername
        The KAS authentication user

    .PARAMETER KasPwd
        The password for your All-Inkl KAS account.

    .PARAMETER KasPwdHash
        The sha1 hash of the password for your All-Inkl KAS account.

    .PARAMETER KasSession
        The session id of an open session on the KAS API. Use this parameter if you want to handle authentication on your own.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $pass = Read-Host "Password" -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' -KasUsername 'userName' -KasPwd $pass

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
        Not required

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

############################
# Helper Functions
############################

# KAS API documentation
# https://kasapi.kasserver.com/dokumentation/

function Get-KasLoginDataFromParameters {
    [CmdletBinding()]
    param(
        [string]$paramSetName,
        [string]$KasUsername,
        [securestring]$KasPwd,
        [securestring]$KasPwdHash,
        [securestring]$KasSession
    )

    # check which parameter to use and set KAS auth type accordingly
    if ('plain' -eq $paramSetName) {
        $secureAuthData = $KasPwd
        $kasAuthType = 'plain'
    }
    elseif ('sha1' -eq $paramSetName) {
        $secureAuthData = $KasPwdHash
        $kasAuthType = 'sha1'
    }
    elseif ('session' -eq $paramSetName) {
        $secureAuthData = $KasSession
        $kasAuthType = 'session'
    }

    # get plaintext from securestring
    $kasAuthData = [pscredential]::new('a',$secureAuthData).GetNetworkCredential().Password

    # return the effective authentication data
    return @{ kas_login=$KasUsername; kas_auth_type=$kasAuthType; kas_auth_data=$kasAuthData }

    <#
    .SYNOPSIS
        Internal helper function that checks all input parameter sets/combinations and returns the effective login data

    .DESCRIPTION
        KAS API supports three different login types: plain/sha1/session
        see https://kasapi.kasserver.com/dokumentation/phpdoc/

        By using the type 'session' it is possible to reuse existing sessions when Posh-ACME is used as a part of a larger script.

        All-Inkl.com users have received warnings that sha1 auth option may be discontinued as of Dec 2022.

    .PARAMETER paramSetName
        The name of the paramSet that was detected by the public methods of this plugin.

    .PARAMETER KasUsername
        The username for the KAS API. The username is required for all login types.

    .PARAMETER KasPwd
        The plain password as securestring.

    .PARAMETER KasPwdHash
        The sha1 hash of the password as securestring.

    .PARAMETER KasSession
        The session id of an existing/open session in KAS as securestring.
    #>
}

function Get-KASDNSSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$loginData,
        [Parameter(Mandatory,Position=1)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone_host mapping
    if (!$script:KASRecordZones) { $script:KASRecordZones = @{} }

    # check for the record in the zone cache
    if ($script:KASRecordZones.ContainsKey($RecordName)) {
        $kasZoneHost = $script:KASRecordZones.$RecordName

        $kasAPIResponse = Invoke-KASAPIGetDNSSettings $loginData $kasZoneHost

        return @{
            zone = $kasZoneHost
            dnsSettings = $kasAPIResponse
        }
    } else {

        # Search for the zone from longest to shortest set of FQDN pieces.
        $pieces = $RecordName.Split('.')
        for ($i=0; $i -lt ($pieces.Count-1); $i++) {
            $zoneTest = $pieces[$i..($pieces.Count-1)] -join '.'

            Write-Debug "Checking zone $zoneTest"

            # skip calling KAS API for _acme-challenge.*
            # The API would return an error zone_syntax_incorrect anyway
            if ($zoneTest.StartsWith("_acme-challenge.")) {
                continue;
            }

            try {
                $kasAPIResponse = Invoke-KASAPIGetDNSSettings $loginData $zoneTest

                # check for results
                if (-not $kasAPIResponse) {
                    continue;
                }

                # since the current $zoneTest returned a result, cache it for future calls
                $script:KASRecordZones.$RecordName = $zoneTest

                return @{
                    zone = $zoneTest
                    dnsSettings = $kasAPIResponse
                }

            }
            catch {
                # Ignore "zone_not_found" and try the next set of FQDN pieces. Throw all other errors
                if (!$_.Exception.Message.Contains("zone_not_found")) {
                    throw
                }
            }
        }

        throw "No zone_host found for $RecordName"
    }

    <#
    .SYNOPSIS
        loads the DNS settings from the KAS API

    .DESCRIPTION
        tries to find the correct zone for the given record name and loads the
        corresponding DNS settings

    .PARAMETER loginData
        a hashtable containing the login data

    .PARAMETER RecordName
        the record name the settings should be loaded for
    #>
}

function Invoke-KASAPIGetDNSSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$loginData,
        [Parameter(Mandatory,Position=1)]
        [string]$zoneHost
    )

    # prepare API params
    $getDnsSettingsParameters = @{
        'zone_host'=$zoneHost
    }

    # call API
    $responseDocument = Invoke-KasApiAction $loginData 'get_dns_settings' $getDnsSettingsParameters

    # check for results
    if (-not $responseDocument) {
        return $null;
    }

    # find ReturnInfo in result
    $returnInfo = Select-XmlFromKASResult $responseDocument "./return/item[contains(key, 'Response')]/value/item[contains(key,'ReturnInfo')]/value"

    if ($returnInfo -and $returnInfo.Node) {
        return $returnInfo.Node
    } else {
        return $null
    }

    <#
    .SYNOPSIS
        invokes the action 'get_dns_settings' on the KAS API

    .DESCRIPTION
        calls the KAS SOAP API, invokes the 'get_dns_settings' action and returns the result

    .PARAMETER loginData
        a hashtable containing the login data

    .PARAMETER zoneHost
        the zone_host parameter that is provided to the KAS API
    #>
}

function Invoke-KasApiAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [hashtable]$loginData,
        [Parameter(Mandatory,Position=1)]
        [string]$kasAPIAction,
        [Parameter(Mandatory,Position=2)]
        [hashtable]$kasParameters
    )

    # wsdl for the api service:     https://kasapi.kasserver.com/soap/wsdl/KasApi.wsdl
    # wsdl for the auth service:    https://kasapi.kasserver.com/soap/wsdl/KasAuth.wsdl
    $kasAPIUri = "https://kasapi.kasserver.com/soap/KasApi.php"

    # init KAS flood delay
    # The KAS API documentation can be read as if the delay is only relevant when calling
    # the same API action multiple times. But tests have shown that it is also enforced when
    # calling different API methods. So we use one generic delay for all calls.
    if (!$script:KASNextRequestTime) { $script:KASNextRequestTime = Get-Date }

    # create parameter hastable
    $paramData = @{
        'kas_action' = $kasAPIAction
        'KasRequestParams' = $kasParameters
    }

    # copy login data to parameters
    foreach($key in $loginData.keys) {
        $paramData[$key] = $loginData[$key]
    }

    # convert parameters to JSON
    $paramJson = $paramData | ConvertTo-Json -Depth 2

    # put parameters in SOAP envelope
    $envelopeXml=@'
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope  xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
                xmlns:tns="https://kasserver.com/"
                xmlns:types="https://kasserver.com/encodedTypes"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <soap:Body soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <q1:KasApi xmlns:q1="urn:xmethodsKasApi">
            <Params xsi:type="xsd:string">
'@ + $paramJson + @'
            </Params>
        </q1:KasApi>
    </soap:Body>
</soap:Envelope>
'@

    try {
        # wait for KAS flood delay if necessary
        $slpFor = (New-TimeSpan -End $script:KASNextRequestTime).TotalMilliseconds
        if ($slpFor -gt 0) {
            Write-Verbose "Waiting ${slpFor}ms for KAS API flood delay..."
            Start-Sleep -Milliseconds $slpFor
        }

        # invoke KAS API
        $response = Invoke-WebRequest "$kasAPIUri" -Body "$envelopeXml" -contentType "text/xml; charset=utf-8" -method POST @Script:UseBasic

        # parse result content as xml
        [xml]$xmlDocument = $response.Content

        # find body element
        $bdy = Select-XmlFromKASResult $xmlDocument '/envelopeNS:Envelope/envelopeNS:Body'

        if ((-not $bdy) -or (-not $bdy.Node)) {
            throw "No body element in KAS API response found."
        }

        # check for a 'Fault' element and throw an error if necessary
        $faultElement = Select-XmlFromKASResult $bdy.Node './envelopeNS:Fault'
        if ($faultElement) {

            if (-not $faultElement.Node) {
                throw "Unexpected error: Fault elementin KAS API response found but Node property was empty."
            }

            $faultString = Select-XmlFromKASResult $faultElement.Node './faultstring'
            $faultDetail = Select-XmlFromKASResult $faultElement.Node './detail'

            if ($faultString -and $faultString.Node) {
                if ($faultDetail -and $faultDetail.Node) {
                    $errorMsg = "KAS API error: " + $faultString.Node.InnerText + " (" + $faultDetail.Node.InnerText + ")"
                } else {
                    $errorMsg = "KAS API error: " + $faultString.Node.InnerText
                }
            } else {
                if ($faultDetail -and $faultDetail.Node) {
                    $errorMsg = "KAS API error: " + $faultDetail.Node.InnerText
                } else {
                    $errorMsg = "KAS API error: unknown error"
                }
            }

            Set-KASFloodDelay $faultElement.Node

            throw $errorMsg
        }

        # check for a 'KasApiResponse' element
        $result = Select-XmlFromKASResult $bdy.Node './resultNS:KasApiResponse'
        if ($result -and $result.Node) {
            Set-KASFloodDelay $result.Node

            return $result.Node
        } else {
            throw "KAS API error: 'KasApiResponse' not found"
        }
    }
    catch {
        Set-KASFloodDelay

        throw "An error occured: " + $_.Exception.Message
    }

    <#
    .SYNOPSIS
        invokes an action on the KAS API

    .DESCRIPTION
        calls the KAS SOAP API, invokes an action and returns the result

    .PARAMETER loginData
        a hashtable containing the login data

    .PARAMETER kasAPIAction
        the action that should be invoked on the KAS API
        available actions: https://kasapi.kasserver.com/dokumentation/phpdoc/packages/API%20Funktionen.html

    .PARAMETER kasParameters
        a hashtable that contains the parameters for the called API action
    #>
}

function Set-KASFloodDelay {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [System.Xml.XmlNode]$elementToSearchIn
    )

    # The documentation of the KAS API could be read as if the delay is only enforced when an API call
    # was successfull. As expected, testing showed, that it is also enforced for failed calls.
    # But unfortunately for failed calls the repsonse doesn't include the waiting time. This is why we will
    # be waiting for the default 2 seconds that succeeded requests normally return when no value was specified.


    # when a XmlNode was specified search it for the flood delay key/value pair
    if ($elementToSearchIn) {
        $floodDelayElement = Select-XmlFromKASResult $elementToSearchIn ".//item[contains(key, 'KasFloodDelay')]/value"

        if ($floodDelayElement -and $floodDelayElement.Node -and ($floodDelayElement.Node.InnerText -gt 0)) {
            $script:KASNextRequestTime = (Get-Date).AddSeconds($floodDelayElement.Node.InnerText)
            return
        }

        $floodDelayElement = Select-XmlFromKASResult $elementToSearchIn ".//kasflooddelay"

        if ($floodDelayElement -and $floodDelayElement.Node -and ($floodDelayElement.Node.InnerText -gt 0)) {
            $script:KASNextRequestTime = (Get-Date).AddSeconds($floodDelayElement.Node.InnerText)
            return
        }
    }

    # set next request time to a default value as fallback
    if ($script:KASNextRequestTime -le (Get-Date)) {
        $script:KASNextRequestTime = (Get-Date).AddSeconds(2)
    }

    <#
    .SYNOPSIS
        searches a KAS API result XmlNode for the flood delay and stores the next request time for the KAS API

    .DESCRIPTION
        Takes a XmlNode from a KAS API result and searches for the flood delay key/value pair.
        When found it stores the value for the next API call. Otherwise it sets a default value.

    .PARAMETER elementToSearchIn
        the parent XmlNode to search in (search root)
    #>
}

function Select-XmlFromKASResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [System.Xml.XmlNode]$parentElement,
        [Parameter(Mandatory,Position=1)]
        [string]$xPathStr
    )

    $xmlNamespaces = @{
        envelopeNS = "http://schemas.xmlsoap.org/soap/envelope/"
        resultNS = "https://kasapi.kasserver.com/soap/KasApi.php"
    };

    $result = Select-Xml -Xml $parentElement -XPath $xPathStr -Namespace $xmlNamespaces

    return $result

    <#
    .SYNOPSIS
        executes a given xpath on a given XmlNode

    .DESCRIPTION
        Takes a XmlNode and executes a xpath on it.

    .PARAMETER parentElement
        the parent XmlNode to search in (search root)

    .PARAMETER xPathStr
        the xpath string to execute
    #>
}

function Find-KASDNSSettingsItemInList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [System.Xml.XmlNode]$parentDNSSettingsElement,
        [Parameter(Mandatory,Position=1)]
        [AllowEmptyString()]
        [string]$recordNameWithoutZone,
        [Parameter(Mandatory,Position=2)]
        [string]$TxtValue
    )
    # search for existing DNS settings for the record
    return Select-XmlFromKASResult $parentDNSSettingsElement @"
./item[
    item[contains(key, 'record_name') and contains(value, '$recordNameWithoutZone')]
    and
    item[contains(key, 'record_type') and contains(value, 'TXT')]
    and
    item[contains(key, 'record_data') and contains(value, '$TxtValue')]
]
"@

    <#
    .SYNOPSIS
        searches a given XmlNode with KAS DNS Settings for matching child items

    .DESCRIPTION
        takes a XmlNode with child items and searches for the correct child by matching record_name, record_type and record_data

    .PARAMETER parentDNSSettingsElement
        the parent XmlNode to search in (search root)

    .PARAMETER recordNameWithoutZone
        the record_name to search for already truncated by the zone

    .PARAMETER TxtValue
        the value of the TXT record
    #>
}
