function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$TencentKeyId,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 3)]
        [securestring]$TencentSecret,
        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$TencentSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the insecure secret to a securestring
    if ('DeprecatedInsecure' -eq $PSCmdlet.ParameterSetName) {
        $TencentSecret = ConvertTo-SecureString $TencentSecretInsecure -AsPlainText -Force
    }

    # find the zone for this record
    try { $zoneName = Find-TencentZone $RecordName $TencentKeyId $TencentSecret } catch { throw }
    Write-Debug "Found zone $zoneName"

    # grab the relative portion of the fqdn
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if ($recShort -eq $RecordName) { $recShort = '@' }

    # query for an existing record
    try { $record = Find-TencentRecord -Domain $zoneName -Subdomain $recShort -RecordType 'TXT'  -RecordValue $TxtValue -TencentKeyId $TencentKeyId -TencentSecret $TencentSecret } catch { throw }
    Write-Debug "Found Record $record"

    if ($null -eq $record) {
        # add the record
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        $body = @{
            Domain     = $zoneName
            RecordType = 'TXT'
            RecordLine = 'Ä¬ÈÏ' #Ä¬ÈÏ
            Value      = $TxtValue
            SubDomain  = $recShort
        }
        $response = Invoke-TencentRest CreateRecord $body $TencentKeyId $TencentSecret
        Invoke-Response $response
        
        return 1
    }
    else {
        Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
        return 0
    }
    


    <#
    .SYNOPSIS
        Add a DNS TXT record to Tencentyun (Tencent Cloud)

    .DESCRIPTION
        Add a DNS TXT record to Tencentyun (Tencent Cloud)

    .PARAMETER RecordName
        The fully quTencentfied name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER TencentKeyId
        The Access Key ID for your Tencentyun account.

    .PARAMETER TencentSecret
        The Access Secret for your Tencentyun account.

    .PARAMETER TencentSecretInsecure
        (DEPRECATED) The Access Secret for your Tencentyun account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "Secret" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key-id' $secret

        Adds a TXT record using a securestring object for TencentSecret. (Only works on Windows)
    #>
}

function Remove-DnsTxt {
    [CmdletBinding(DefaultParameterSetName = 'Secure')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$TencentKeyId,
        [Parameter(ParameterSetName = 'Secure', Mandatory, Position = 3)]
        [securestring]$TencentSecret,
        [Parameter(ParameterSetName = 'DeprecatedInsecure', Mandatory, Position = 3)]
        [string]$TencentSecretInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # convert the insecure secret to a securestring
    if ('DeprecatedInsecure' -eq $PSCmdlet.ParameterSetName) {
        $TencentSecret = ConvertTo-SecureString $TencentSecretInsecure -AsPlainText -Force
    }

    # find the zone for this record
    try { $zoneName = Find-TencentZone $RecordName $TencentKeyId $TencentSecret } catch { throw }
    Write-Debug "Found zone $zoneName"

    # grab the relative portion of the fqdn
    $recShort = ($RecordName -ireplace [regex]::Escape($zoneName), [string]::Empty).TrimEnd('.')
    if ($recShort -eq $RecordName) { $recShort = '@' }

    # query for an existing record
    try { $record = Find-TencentRecord -Domain $zoneName -Subdomain $recShort -RecordType 'TXT'  -RecordValue $TxtValue -TencentKeyId $TencentKeyId -TencentSecret $TencentSecret } catch { throw }
    Write-Debug "Found Record $record"

    if ($null -eq $record) {
        Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        return 0
    }
    else { 
        # remove the record
        Write-Verbose "Removing TXT record for $RecordName with RecordId $record.RecordId " 
        $body = @{
            Domain   = $zoneName
            RecordId = $record.RecordId 
        }
        $response = Invoke-TencentRest DeleteRecord $body $TencentKeyId $TencentSecret
        Invoke-Response $response
        return 1
    }     


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Tencentyun (Tencent Cloud)

    .DESCRIPTION
        Remove a DNS TXT record from Tencentyun (Tencent Cloud)

    .PARAMETER RecordName
        The fully quTencentfied name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER TencentKeyId
        The Access Key ID for your Tencentyun account.

    .PARAMETER TencentSecret
        The Access Secret for your Tencentyun account.

    .PARAMETER TencentSecretInsecure
        (DEPRECATED) The Access Secret for your Tencentyun account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $secret = Read-Host "Secret" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'key-id' $secret

        Removes a TXT record using a securestring object for TencentSecret. (Only works on Windows)
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

# API Docs
#  https://cloud.tencent.com/document/api/1427
function Invoke-TencentRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$action,
        [Parameter(Position = 1)]
        [Object]$bodyData,
        [Parameter(Mandatory, Position = 2)]
        [string]$secretId,
        [Parameter(Mandatory, Position = 3)]
        [securestring]$AccessSecret
    )

    $secretKey = [pscredential]::new('a', $AccessSecret).GetNetworkCredential().Password
    $body = $bodyData | ConvertTo-Json -Compress
    Write-Debug "body $body"
    # BuildRequest
    $region = ""
    $token = ""
    $version = "2021-03-23"
    #$service   = "dnspod"
    $apihost = "dnspod.tencentcloudapi.com"
    $url = "https://$apihost"
    $contentType = "application/json;charset=utf-8"

    $epochStart = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $timestamp = [Math]::Round((Get-Date).ToUniversalTime().Subtract($epochStart).TotalSeconds)   

    # Signature mechanism
    # https://cloud.tencent.com/document/api/1427/56189
    $auth = GetAuth -secretId $secretId -secretKey $secretKey -apihost $apihost -contentType $contentType -timestamp $timestamp -body $body -action $action

    $headers = @{
        'Authorization'      = $auth
        'User-Agent'         = ''
        'Host'               = $apihost
        'X-TC-Timestamp'     = $timestamp
        'X-TC-Version'       = $version
        'X-TC-Action'        = $action
        'X-TC-Region'        = $region
        'X-TC-Token'         = $token
    }
    
    $response = Invoke-RestMethod -Method 'Post' -Uri $url -Headers $headers -Body $body -contenttype $contentType # @script:UseBasic # -EA Stop
    return $response
}

function GetAuth {
    [CmdletBinding()]
    param(
        [string]$secretId,
        [string]$secretKey,
        [string]$apihost,
        [string]$contentType,
        [long]$timestamp,
        [string]$body,
        [string]$action
    )

    $canonicalURI = "/"
    $xtcaction = $action.ToLower()
    $canonicalHeaders = "content-type:$contentType`nhost:$apihost`nx-tc-action:$xtcaction`n"
    $signedHeaders = "content-type;host;x-tc-action"
    $hashedRequestPayload = Sha256Hex $body
    $canonicalRequest = "POST`n$canonicalURI`n`n$canonicalHeaders`n$signedHeaders`n$hashedRequestPayload"

    Write-Debug "canonicalRequest $canonicalRequest"

    $algorithm = "TC3-HMAC-SHA256"
    $epochStart = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $timestampDateTime = $epochStart.AddSeconds($timestamp)
    $date = $timestampDateTime.ToString("yyyy-MM-dd") 
    $service = $apihost.Split(".")[0]
    $credentialScope = "$date/$service/tc3_request"
    $hashedCanonicalRequest = Sha256Hex $canonicalRequest
    $stringToSign = "$algorithm`n$timestamp`n$credentialScope`n$hashedCanonicalRequest"

    Write-Debug "stringToSign $stringToSign"

    $tc3SecretKey = [Text.Encoding]::UTF8.GetBytes("TC3" + $secretKey)
    $secretDate = HmacSha256 -key $tc3SecretKey -msg ([Text.Encoding]::UTF8.GetBytes($date))
    $secretService = HmacSha256 -key $secretDate -msg ([Text.Encoding]::UTF8.GetBytes($service))
    $secretSigning = HmacSha256 -key $secretService -msg ([Text.Encoding]::UTF8.GetBytes("tc3_request"))
    $signatureBytes = HmacSha256 -key $secretSigning -msg ([Text.Encoding]::UTF8.GetBytes($stringToSign))
    $signature = ($signatureBytes | ForEach-Object { $_.ToString("x2") }) -join ''
    $signature = $signature.ToLower() 

    $auth = "$algorithm Credential=$secretId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"
    Write-Debug "auth $auth"
    return $auth
}

function Sha256Hex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]$inputString
    )

    $sha256 = [System.Security.Cryptography.SHA256Managed]::Create()
    $inputBytes = [System.Text.Encoding]::UTF8.GetBytes($inputString)
    $hashBytes = $sha256.ComputeHash($inputBytes)
    $hashHexString = [BitConverter]::ToString($hashBytes) -replace "-"

    return $hashHexString.ToLower()
}

function HmacSha256 {
    [CmdletBinding()]
    param(
        [byte[]]$key,
        [byte[]]$msg
    )

    $mac = [System.Security.Cryptography.HMACSHA256]::new($key)
    return $mac.ComputeHash($msg)
}
function Invoke-Response {
    [CmdletBinding()]
    param(
        [object]$response
    )
    if ($response.Response.Error) {
        $strRps = $response | ConvertTo-Json -Compress
        Write-Warning "Response Error  $strRps"
        throw
    }
 
}

function Find-TencentZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TencentKeyId,
        [Parameter(Mandatory, Position = 2)]
        [securestring]$TencentSecret
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:TencentRecordZones) { $script:TencentRecordZones = @{} }

    # check for the record in the cache
    if ($script:TencentRecordZones.ContainsKey($RecordName)) {
        return $script:TencentRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    $pieces = $RecordName.Split('.')
    for ($i = 0; $i -lt ($pieces.Count - 1); $i++) {
        $zoneTest = $pieces[$i..($pieces.Count - 1)] -join '.'
        Write-Debug "Checking $zoneTest"
        try {
            $body = @{
                Keyword = $zoneTest
            }
            $response = Invoke-TencentRest DescribeDomainList $body $TencentKeyId $TencentSecret

            # check for results
            if ($response.Response.DomainCountInfo.DomainTotal -gt 0) {
                $script:TencentRecordZones.$RecordName = $response.Response.DomainList[0].Name # or PunyCode?
                return $script:TencentRecordZones.$RecordName
            }
        }
        catch { throw }
    }

    throw "No zone found for $RecordName"
}
function Find-TencentRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Domain,
        [Parameter(Mandatory, Position = 1)]
        [string]$Subdomain,
        [Parameter(Mandatory, Position = 2)]
        [string]$RecordType,
        [Parameter(Position = 3)]
        [string]$RecordValue,
        [Parameter(Mandatory, Position = 4)]
        [string]$TencentKeyId,
        [Parameter(Mandatory, Position = 5)]
        [securestring]$TencentSecret
    )

    try {
        $body = @{
            Domain     = $Domain
            Subdomain  = $Subdomain
            #Keyword =$TxtValue # can not add this param
            RecordType = $RecordType
        }
        $response = Invoke-TencentRest DescribeRecordList $body $TencentKeyId $TencentSecret
    }
    catch { throw }
    
    if ($response.Response.RecordCountInfo.TotalCount -gt 0) {    
        
        $recordList = $response.Response.RecordList
        if ($RecordValue -eq $null) {
            return $recordList[0]
        }    
        # found data . then foreach
        for ($i = 0; $i -lt ($recordList.Count); $i++) {
            
            $item = $recordList[$i]
            if ($item.Value -eq $RecordValue) {
                #Write-Debug "Find RecordItem $item"
                return $item
            }
            
        }

    }
    Write-Debug "No Record found for $Domain Subdomain $Subdomain  RecordType $RecordType RecordValue $RecordValue"     
}
