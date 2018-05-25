function Add-DnsTxtRoute53 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # For now, we're going to use the AwsPowershell module for both types of credentials.
    # But my hope is to eventually remove the AwsPowershell module dependency (which is
    # currently 75 MB by itself) for people who use the Access/Secret key pair.

    # make sure the correct module is available for the PS edition
    if ($PSEdition -eq 'Core') { $modName = 'AwsPowershell.NetCore' } else { $modName = 'AwsPowershell' }
    if (!(Get-Module -ListAvailable $modName -Verbose:$false)) {
        throw "The $modName module is required to use this plugin."
    } else {
        Import-Module $modName -Verbose:$false
    }

    if ('Keys' -eq $PSCmdlet.ParameterSetName) {
        $credParam = @{AccessKey=$R53AccessKey; SecretKey=((New-Object PSCredential "user",$R53SecretKey).GetNetworkCredential().Password)}
    } else {
        $credParam = @{ProfileName=$R53ProfileName}
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName $credParam)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    # It's possible there could already be a TXT record for this name with one or more existing
    # values and we don't want to overwrite them. So check first and add to it if it exists.
    $response = Get-R53ResourceRecordSet $zoneID $RecordName 'TXT' @credParam
    $rrSet = $response.ResourceRecordSets | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }
    if ($rrSet.ResourceRecords) {
        # add to the existing record
        $rrSet.ResourceRecords += @{Value="`"$TxtValue`""}
    } else {
        # create a new one
        $rrSet = New-Object Amazon.Route53.Model.ResourceRecordSet
        $rrSet.Name = $RecordName
        $rrSet.Type = 'TXT'
        $rrSet.TTL = 0
        $rrSet.ResourceRecords.Add(@{Value="`"$TxtValue`""})
    }

    # send the change
    Write-Verbose "Adding the record to zone ID $zoneID"
    $change = New-Object Amazon.Route53.Model.Change
    $change.Action = 'UPSERT'
    $change.ResourceRecordSet = $rrSet
    Edit-R53ResourceRecordSet -HostedZoneId $zoneID -ChangeBatch_Change $change @credParam | Out-Null

    <#
    .SYNOPSIS
        Add a DNS TXT record to a Route53 hosted zone.

    .DESCRIPTION
        This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKey
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretKey
        The Secret Key for the IAM account specified by -R53AccessKey.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AwsPowershell module. This only works if the AwsPowershell module is installed.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtRoute53 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=2)]
        [string]$R53AccessKey,
        [Parameter(ParameterSetName='Keys',Mandatory,Position=3)]
        [securestring]$R53SecretKey,
        [Parameter(ParameterSetName='Profile',Mandatory)]
        [string]$R53ProfileName,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # For now, we're going to use the AwsPowershell module for both types of credentials.
    # But my hope is to eventually remove the AwsPowershell module dependency (which is
    # currently 75 MB by itself) for people who use the Access/Secret key pair.

    if ('Keys' -eq $PSCmdlet.ParameterSetName) {
        $credParam = @{AccessKey=$R53AccessKey; SecretKey=((New-Object PSCredential "user",$R53SecretKey).GetNetworkCredential().Password)}
    } else {
        $credParam = @{ProfileName=$R53ProfileName}
    }

    Write-Verbose "Attempting to find hosted zone for $RecordName"
    if (!($zoneID = Get-R53ZoneId $RecordName $credParam)) {
        throw "Unable to find Route53 hosted zone for $RecordName"
    }

    # The TXT record for this name could potentially have multiple values and we only want to
    # remove this specific one.
    $response = Get-R53ResourceRecordSet $zoneID $RecordName 'TXT' @credParam
    $rrSet = $response.ResourceRecordSets | Where-Object { $_.Name -eq "$RecordName." -and $_.Type -eq 'TXT' }

    $change = New-Object Amazon.Route53.Model.Change
    $change.ResourceRecordSet = $rrSet

    if (!$rrSet) {
        Write-Verbose "TXT record for $Record name not found. Already deleted?"
        return
    } elseif ($rrSet.ResourceRecords.Count -gt 1) {
        # update the values to exclude one we want to delete
        $change.Action = 'UPSERT'
        $rrSet.ResourceRecords = $rrSet.ResourceRecords | Where-Object { $_.Value -ne "`"$TxtValue`"" }
    } else {
        # just delete the record
        $change.Action = 'DELETE'
    }

    # remove the record
    Write-Verbose "Removing the record from zone ID $zoneID"
    Edit-R53ResourceRecordSet -HostedZoneId $zoneID -ChangeBatch_Change $change @credParam | Out-Null

    <#
    .SYNOPSIS
        Remove a DNS TXT record from a Route53 hosted zone.

    .DESCRIPTION
        This plugin currently requires the AwsPowershell module to be installed. For authentication to AWS, you can either specify an Access/Secret key pair or the name of an AWS credential profile previously stored using Set-AWSCredential.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER R53AccessKey
        The Access Key ID for the IAM account with permissions to write to the specified hosted zone.

    .PARAMETER R53SecretKey
        The Secret Key for the IAM account specified by -R53AccessKey.

    .PARAMETER R53ProfileName
        The profile name of a previously stored credential using Set-AWSCredential from the AwsPowershell module. This only works if the AwsPowershell module is installed.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtRoute53 '_acme-challenge.site1.example.com' 'asdfqwer12345678'

        Removes a TXT record for the specified site with the specified value.
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

function Get-R53ZoneId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$CredParam
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:R53RecordZones) { $script:R53RecordZones = @{} }

    # check for the record in the cache
    if ($script:R53RecordZones.ContainsKey($RecordName)) {
        return $script:R53RecordZones.$RecordName
    }

    # get the list of available zones
    $zones = Get-R53HostedZoneList @CredParam

    # Since Route53 could be hosting both apex and sub-zones, we need to find the closest/deepest
    # sub-zone that would hold the record rather than just adding it to the apex. So for something
    # like _acme-challenge.site1.sub1.sub2.example.com, we'd look for zone matches in the following
    # order:
    # - site1.sub1.sub2.example.com
    # - sub1.sub2.example.com
    # - sub2.example.com
    # - example.com

    $pieces = $RecordName.Split('.')
    for ($i=1; $i -lt ($pieces.Count-1); $i++) {
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
