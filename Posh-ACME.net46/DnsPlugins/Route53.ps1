function Add-DnsTxtRoute53 {
    [CmdletBinding(DefaultParameterSetName='Keys')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=2)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=3)]
        [string]$R53SecretKeyInsecure,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ParameterSetName='IAMRole',Mandatory)]
        [switch]$R53UseIAMRole,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Initialize-R53Config @PSBoundParameters

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    if ($script:AwsUseModule) {

        # Check for an existing TXT record with this name
        $response = Get-R53ResourceRecordSet $zoneID $RecordName 'TXT' @script:AwsCredParam
        $rrSet = $response.ResourceRecordSets | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }

        if ($rrSet) {
            if ("`"$TxtValue`"" -in $rrSet.ResourceRecords.Value) {
                Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
                return
            }
            # add a value the existing record
            $rrSet.ResourceRecords += @{Value="`"$TxtValue`""}
        } else {
            # create a new rrset
            $rrSet = New-Object Amazon.Route53.Model.ResourceRecordSet
            $rrSet.Name = $RecordName
            $rrSet.Type = 'TXT'
            $rrSet.TTL = 60
            $rrSet.ResourceRecords.Add(@{Value="`"$TxtValue`""})
        }

        # send the change
        Write-Verbose "Adding the record to zone ID $zoneID"
        $change = New-Object Amazon.Route53.Model.Change
        $change.Action = 'UPSERT'
        $change.ResourceRecordSet = $rrSet
        $null = Edit-R53ResourceRecordSet -HostedZoneId $zoneID -ChangeBatch_Change $change @script:AwsCredParam

    } else {

        # Check for an existing TXT record with this name
        $ep = "/2013-04-01$zoneID/rrset"
        $qs = "name=$RecordName&type=TXT"
        $response = (Invoke-R53RestMethod -Endpoint $ep -QueryString $qs @script:AwsCredParam).ListResourceRecordSetsResponse
        $rrSet = $response.ResourceRecordSets.ResourceRecordSet | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }

        if ($rrSet) {
            if ("`"$TxtValue`"" -in $rrSet.ResourceRecords.ResourceRecord.Value) {
                Write-Debug "Record $RecordName already contains $TxtValue. Nothing to do."
                return
            }

            # parse out the list of <RecordSet> elements that we'll be appending to
            # There's probably a more elegant way to do this via builtin methods or xpath, but I'm lazy
            $rrSetXml = $rrSet.OuterXml
            $iStart = $rrSetXml.IndexOf('<ResourceRecord>')
            $rrXml = $rrSetXml.Substring($iStart)
            $iEnd = $rrXml.IndexOf('</ResourceRecords>')
            $rrXml = $rrXml.Substring(0,$iEnd)
        }

        # build the UPSERT xml
        $xmlBody = "<ChangeResourceRecordSetsRequest xmlns=`"https://route53.amazonaws.com/doc/2013-04-01/`"><ChangeBatch><Changes><Change><Action>UPSERT</Action><ResourceRecordSet><Name>$RecordName</Name><Type>TXT</Type><TTL>300</TTL><ResourceRecords>$rrXml<ResourceRecord><Value>`"$TxtValue`"</Value></ResourceRecord></ResourceRecords></ResourceRecordSet></Change></Changes></ChangeBatch></ChangeResourceRecordSetsRequest>"

        # send the update
        $null = Invoke-R53RestMethod -Endpoint $ep -UsePost -Data $xmlBody @script:AwsCredParam
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to a Route53 hosted zone.

    .DESCRIPTION
        For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKey
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretKey
        The Secret Key for the IAM account specified by -R53AccessKey. This SecureString version should only be used on Windows.

    .PARAMETER R53SecretKeyInsecure
        The Secret Key for the IAM account specified by -R53AccessKey. This standard String version should be used on non-Windows OSes.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AWS PowerShell module. This only works if the module is installed.

    .PARAMETER R53UseIAMRole
        If specified, the module will attempt to authenticate using the AWS metadata service via an associated IAM Role. This will only work if the system is running within AWS and has been assigned an IAM Role with the proper permissions.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53ProfileName 'myprofile'

        Add a TXT record using a profile name saved in the AWS PowerShell module.

    .EXAMPLE
        $seckey = Read-Host -Prompt 'Secret Key:' -AsSecureString
        PS C:\>Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKey $seckey

        Add a TXT record using an explicit Access Key and Secret key from Windows.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKeyInsecure 'yyyyyyyy'

        Add a TXT record using an explicit Access Key and Secret key from a non-Windows OS.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53UseIAMRole

        Add a TXT record using implicit credential from an associated IAM Role.
    #>
}

function Remove-DnsTxtRoute53 {
    [CmdletBinding(DefaultParameterSetName='Keys')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=2)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=3)]
        [string]$R53SecretKeyInsecure,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ParameterSetName='IAMRole',Mandatory)]
        [switch]$R53UseIAMRole,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    Initialize-R53Config @PSBoundParameters

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    if ($script:AwsUseModule) {

        # Check for an existing TXT record with this name
        $response = Get-R53ResourceRecordSet $zoneID $RecordName 'TXT' @script:AwsCredParam
        $rrSet = $response.ResourceRecordSets | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }

        if (-not $rrSet -or "`"$TxtValue`"" -notin $rrSet.ResourceRecords.Value) {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
            return
        } else {
            # begin a change request
            $change = New-Object Amazon.Route53.Model.Change
            $change.ResourceRecordSet = $rrSet

            if ($rrSet.ResourceRecords.Count -gt 1) {
                # update the values to exclude one we want to delete
                $change.Action = 'UPSERT'
                $rrSet.ResourceRecords = $rrSet.ResourceRecords | Where-Object { $_.Value -ne "`"$TxtValue`"" }
            } else {
                # just delete the record
                $change.Action = 'DELETE'
            }

            # remove the record
            Write-Verbose "Removing the record from zone ID $zoneID"
            $null = Edit-R53ResourceRecordSet -HostedZoneId $zoneID -ChangeBatch_Change $change @script:AwsCredParam
        }

    } else {

        # Check for an existing TXT record with this name
        $ep = "/2013-04-01$zoneID/rrset"
        $qs = "name=$RecordName&type=TXT"
        $response = (Invoke-R53RestMethod -Endpoint $ep -QueryString $qs @script:AwsCredParam).ListResourceRecordSetsResponse
        $rrSet = $response.ResourceRecordSets.ResourceRecordSet | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }

        if (-not $rrSet -or "`"$TxtValue`"" -notin $rrSet.ResourceRecords.ResourceRecord.Value) {
            Write-Debug "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
            return
        } else {

            # parse out the list of <RecordSet> elements that we'll be removing from
            # There's probably a more elegant way to do this via builtin methods or xpath, but I'm lazy
            $rrSetXml = $rrSet.OuterXml
            $iStart = $rrSetXml.IndexOf('<ResourceRecord>')
            $rrXml = $rrSetXml.Substring($iStart)
            $iEnd = $rrXml.IndexOf('</ResourceRecords>')
            $rrXml = $rrXml.Substring(0,$iEnd)

            # check if this is the last value or not
            if (@($rrSet.ResourceRecords.ResourceRecord).Count -gt 1) {
                # remove the RecordSet value that we're deleting
                $rrXml = $rrXml.Replace("<ResourceRecord><Value>`"$TxtValue`"</Value></ResourceRecord>",'')
                $action = 'UPSERT'
            } else {
                $action = 'DELETE'
            }
        }

        # build the xml body
        $xmlBody = "<ChangeResourceRecordSetsRequest xmlns=`"https://route53.amazonaws.com/doc/2013-04-01/`"><ChangeBatch><Changes><Change><Action>$action</Action><ResourceRecordSet><Name>$RecordName</Name><Type>TXT</Type><TTL>300</TTL><ResourceRecords>$rrXml</ResourceRecords></ResourceRecordSet></Change></Changes></ChangeBatch></ChangeResourceRecordSetsRequest>"

        # send the update
        $null = Invoke-R53RestMethod -Endpoint $ep -UsePost -Data $xmlBody @script:AwsCredParam
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from a Route53 hosted zone.

    .DESCRIPTION
        For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKey
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretKey
        The Secret Key for the IAM account specified by -R53AccessKey. This SecureString version should only be used on Windows.

    .PARAMETER R53SecretKeyInsecure
        The Secret Key for the IAM account specified by -R53AccessKey. This standard String version should be used on non-Windows OSes.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AWS PowerShell module. This only works if the module is installed.

    .PARAMETER R53UseIAMRole
        If specified, the module will attempt to authenticate using the AWS metadata service via an associated IAM Role. This will only work if the system is running within AWS and has been assigned an IAM Role with the proper permissions.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53ProfileName 'myprofile'

        Remove a TXT record using a profile name saved in the AWS PowerShell module.

    .EXAMPLE
        $seckey = Read-Host -Prompt 'Secret Key:' -AsSecureString
        PS C:\>Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKey $seckey

        Remove a TXT record using an explicit Access Key and Secret key from Windows.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53AccessKey 'xxxxxxxx' -R53SecretKeyInsecure 'yyyyyyyy'

        Remove a TXT record using an explicit Access Key and Secret key from a non-Windows OS.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678' -R53UseIAMRole

        Remove a TXT record using implicit credential from an associated IAM Role.
    #>
}

function Save-DnsTxtRoute53 {
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

function Initialize-R53Config {
    [CmdletBinding(DefaultParameterSetName='Keys')]
    param (
        [Parameter(ParameterSetName='Keys',Mandatory,Position=0)]
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=0)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=1)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='KeysInsecure',Mandatory,Position=1)]
        [string]$R53SecretKeyInsecure,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ParameterSetName='IAMRole',Mandatory)]
        [switch]$R53UseIAMRole,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraConnectParams
    )

    # We now have the ability to do direct REST calls against AWS without depending
    # on AWS's own PowerShell module as long as the user provided explicit keys
    # rather than a profile name. However, we're still going to prefer using the
    # module if it's installed because it's less likely to break over time if
    # AWS updates the REST API requirements. Or rather, fixing it should be as
    # simple as installing an updated version of the module.

    # Prior to version 4 of the AWS PowerShell Tools, the module was called
    # AWSPowerShell or AWSPowerShell.NetCore depending on the PowerShell edition
    # you were on. Both were single monolithic modules. In version 4, they've
    # split all the features into sub-modules, but there are no distinctions
    # between editions anymore. For Route53 specifically, we care about
    # AWS.Tools.Route53. Thankfully, everything in 4 is backwards compatible with
    # 3, so we don't need to do any special casing depending on which module is
    # installed.

    # check for AWS module availability
    if ($null -ne (Get-Module -ListAvailable 'AWS.Tools.Route53')) {
        Import-Module 'AWS.Tools.Route53' -Verbose:$false
        $script:AwsUseModule = $true
    }
    elseif ($PSEdition -eq 'Core' -and
            $null -ne (Get-Module -ListAvailable 'AWSPowerShell.Netcore')) {
        Import-Module 'AWSPowerShell.NetCore' -Verbose:$false
        $script:AwsUseModule = $true
    }
    elseif ($null -ne (Get-Module -ListAvailable 'AWSPowerShell')) {
        Import-Module 'AWSPowerShell' -Verbose:$false
        $script:AwsUseModule = $true
    }
    else {
        Write-Verbose "An AWS PowerShell module for Route53 was not found. https://docs.aws.amazon.com/powershell/"
        $script:AwsUseModule = $false
    }

    # build and save the credential parameter(s)
    switch ($PSCmdlet.ParameterSetName) {
        'Keys' {
            $secPlain = (New-Object PSCredential "user",$R53SecretKey).GetNetworkCredential().Password
            $script:AwsCredParam = @{AccessKey=$R53AccessKey; SecretKey=$secPlain}
            break
        }
        'KeysInsecure' {
            $script:AwsCredParam = @{AccessKey=$R53AccessKey; SecretKey=$R53SecretKeyInsecure}
            break
        }
        'IAMRole' {
            if ($script:AwsUseModule) {
                # the module will use the IAMRole by default if nothing else is specified
                $script:AwsCredParam = @{}
            } else {
                # retrieve keys+token from the metadata service for the IAMRole
                $credBase = "http://169.254.169.254/latest/meta-data/iam/security-credentials"
                try { $role = Invoke-RestMethod "$credBase" @script:UseBasic } catch {}
                if (-not $role) {
                    throw "No IAM Role found in the metadata service."
                }
                $cred = Invoke-RestMethod "$credBase/$role" @script:UseBasic

                $script:AwsCredParam = @{
                    AccessKey = $cred.AccessKeyId
                    SecretKey = $cred.SecretAccessKey
                    Token = $cred.Token
                }
            }
        }
        default {
            # the only thing left is profile name which requires the module
            # so error if we didn't find it
            if (-not $script:AwsUseModule) {
                throw "An AWS PowerShell module is required to use this plugin with the R53ProfileName parameter. https://docs.aws.amazon.com/powershell/"
            }
            $script:AwsCredParam = @{ProfileName=$R53ProfileName}
        }
    }

}

function Get-AwsHash {
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [string]$Data
    )
    # Need a SHA256 hash in lowercase hex with no dashes
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($Data))
    return ([BitConverter]::ToString($hash) -replace '-','').ToLower()
}

function Invoke-R53RestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AccessKey,
        [Parameter(Mandatory)]
        [string]$SecretKey,
        [string]$Token,
        [switch]$UsePost,                       # default to GET unless this is used
        [string]$Endpoint='/',                  # e.g. CanonicalUri like "/2013-04-01/hostedzone"
        [string]$QueryString=[String]::Empty,   # e.g. CanonicalQueryString like "name=example.com&type=TXT"
        [string]$Data=[String]::Empty
    )

    # The convoluted process that is authenticating against AWS using Signature Version 4
    # https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html

    # Since we're only ever using Route53, we can hard code a few things
    $awsHost = 'route53.amazonaws.com'
    $region = 'us-east-1'
    $service = 'route53'
    $terminator = 'aws4_request'


    # For some reason we need two differently formatted date strings
    $now = [DateTimeOffset]::UtcNow
    $nowDate = $now.ToString("yyyyMMdd")
    $nowDateTime = $now.ToString("yyyyMMddTHHmmssZ")

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    $CanonicalHeaders = "host:$awsHost`nx-amz-date:$nowDateTime`n"
    $SignedHeaders = "host;x-amz-date"

    $Method = if ($UsePost) { 'POST' } else { 'GET' }
    $CanonicalRequest = "$Method`n$Endpoint`n$QueryString`n$CanonicalHeaders`n$SignedHeaders`n$((Get-AwsHash $Data))"
    Write-Debug "CanonicalRequest:`n$CanonicalRequest"
    $CanonicalRequestHash = Get-AwsHash $CanonicalRequest

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    $CredentialScope = "$nowDate/$region/$service/$terminator"

    $StringToSign = "AWS4-HMAC-SHA256`n$nowDateTime`n$CredentialScope`n$CanonicalRequestHash"
    Write-Debug "StringToSign:`n$StringToSign"

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes("AWS4$SecretKey")
    $kDate = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($nowDate))

    $hmac.Key = $kDate
    $kRegion = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($region))

    $hmac.Key = $kRegion
    $kService = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($service))

    $hmac.Key = $kService
    $kSigning = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($terminator))

    $hmac.Key = $kSigning
    $signature = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($StringToSign))
    $sigHex = ([BitConverter]::ToString($signature) -replace '-','').ToLower()

    # https://docs.aws.amazon.com/general/latest/gr/sigv4-add-signature-to-request.html
    $Authorization = "AWS4-HMAC-SHA256 Credential=$AccessKey/$CredentialScope, SignedHeaders=$SignedHeaders, Signature=$sigHex"
    Write-Debug "Auth:`n$Authorization"

    # build the request params header hashtable
    $headers = @{
        'x-amz-date' = $nowDateTime
        Authorization = $Authorization
    }

    # X-Amz-Security-Token
    # add the security/session token header if it was specified
    # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html
    if ($Token) {
        $headers.'x-amz-security-token' = $Token
    }

    $uri = "https://$awsHost$($Endpoint)"
    if ([String]::Empty -ne $QueryString) {
        $uri += "?$QueryString"
    }

    $irmArgs = @{
        Uri = $uri
        Headers = $headers
    }
    if ($UsePost) {
        $irmArgs.Method = 'Post'
        $irmArgs.Body = $Data
    }
    if ('SkipHeaderValidation' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        # PS Core doesn't like the way AWS's Authorization header looks for some
        # reason. So we need to disable its built-in validation.
        $irmArgs.SkipHeaderValidation = $true
    }

    try {
        return (Invoke-RestMethod @irmArgs @script:UseBasic)
    } catch { throw }
}

function Get-R53ZoneId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:R53RecordZones) { $script:R53RecordZones = @{} }

    # check for the record in the cache
    if ($script:R53RecordZones.ContainsKey($RecordName)) {
        return $script:R53RecordZones.$RecordName
    }

    # Since there's no good way to query the existence of a single zone, we have to fetch all of them
    if ($script:AwsUseModule) {
        # fetch via Module
        $zones = Get-R53HostedZoneList @script:AwsCredParam | Where-Object { $_.Config.PrivateZone -eq $false }
    } else {
        # fetch via REST
        $zones = @()
        $nextMarker = ''
        do {
            $response = (Invoke-R53RestMethod @script:AwsCredParam -Endpoint '/2013-04-01/hostedzone' -QueryString $nextMarker).ListHostedZonesResponse
            $zones += @(($response.HostedZones.HostedZone | Where-Object { $_.Config.PrivateZone -eq 'false' }))

            # check for paging
            if ([String]::IsNullOrWhiteSpace($response.NextMarker)) { break }
            $nextMarker = "marker=$($response.NextMarker)&"
        } while ($true)
    }
    Write-Debug "Total zones: $($zones.Count)"

    # Loop through increasingly general sub-zones to find the most specific
    # zone this record should live in.
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zoneTest = "$( $pieces[$i..($pieces.Count-1)] -join '.' )."
        Write-Verbose "Checking $zoneTest"

        if ($zoneTest -in $zones.Name) {
            $zoneID = ($zones | Where-Object { $_.Name -eq $zoneTest }).Id
            $script:R53RecordZones.$RecordName = $zoneID
            return $zoneID
        }
    }

    return $null
}
