
Function Add-DnsTxtEasyDNS{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [string]$edToken,
        [string]$edKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    #Basic Setup - set use live REST URL for easyDNS and manually encode token/key pair into header
    $URI = "https://sandbox.rest.easydns.net"
    $pair = "$($edToken):$($edKey)"

    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"
    $Headers = @{Authorization = $basicAuthValue}

    #Split up the Recordname into host and domain by testing against account
    $Bits = $RecordName.Split('.') | ? {$_ -ne '*'}
    for ($i=2; $i -lt $Bits.Count; $i++) {
        try{$Records=Invoke-RestMethod -Uri "$($URI)/zones/records/all/$($Bits[$(0-$i)..-1] -join '.')?format=json" -ContentType 'application/json' -Headers $Headers -Method GET @script:UseBasic -ErrorAction Stop}
        catch {continue}
        $domain = $Bits[$(0-$i)..-1] -join '.'
        Write-Verbose $domain
        break
    }
    if (!$domain) {throw "Could not find domain"}

    $hostname = $Bits[0..$($i-1)] -join '.'

    Write-Verbose "Check for duplicate"
    foreach ($zRecord in $($Records.data | ? {$_.host -eq $hostname -and $_.rData -eq $TxtValue})) {
        Write-Verbose "Duplicate found... Deleting"
        $DeleteResponse = Invoke-RestMethod -Uri "$($URI)/zones/records/$($domain)/$($zRecord.id)?format=json" -ContentType 'application/json' -Headers $Headers -Method Delete @script:UseBasic
    }

    $NewHost = @{
    host = $hostname
    domain = $domain
    ttl = 0
    prio = 0
    type = "txt"
    rdata = $TxtValue
    }

    Write-Verbose "Create new record"
    $CreateResponse = Invoke-RestMethod -Body ($NewHost|ConvertTo-Json) -Uri "$($URI)/zones/records/add/$($domain)/txt?format=json" -ContentType 'application/json' -Headers $Headers -Method PUT @script:UseBasic
        <#
    .SYNOPSIS
        Add a DNS TXT record to EasyDNS.

    .DESCRIPTION
        Add a DNS TXT record to EasyDNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER edToken
        The EasyDNS API Token.

    .PARAMETER edKey
        The EasyDNS API Key.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtEasyDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dfasdasf3j42f' 'adsfj834sadfda'

        Adds a TXT record for the specified site with the specified value.
    #>
}

Function Remove-DnsTxtEasyDNS{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [string]$edToken,
        [string]$edKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    #Basic Setup - set use live REST URL for easyDNS and manually encode token/key pair into header
    $URI = "https://sandbox.rest.easydns.net"
    $pair = "$($edToken):$($edKey)"

    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"
    $Headers = @{Authorization = $basicAuthValue}

    #Split up the Recordname into host and domain by testing against account
    $Bits = $RecordName.Split('.') | ? {$_ -ne '*'}
    for ($i=2; $i -lt $Bits.Count; $i++) {
        try{$Records=Invoke-RestMethod -Uri "$($URI)/zones/records/all/$($Bits[$(0-$i)..-1] -join '.')?format=json" -ContentType 'application/json' -Headers $Headers -Method GET @script:UseBasic -ErrorAction Stop}
        catch {continue}
        $domain = $Bits[$(0-$i)..-1] -join '.'
        Write-Verbose $domain
        break
    }
    if (!$domain) {throw "Could not find domain"}

    $hostname = $Bits[0..$($i-1)] -join '.'

    Write-Verbose "Check for matching record $hostname | $domain | $TxtValue"
    foreach ($zRecord in $($Records.data | ? {$_.host -eq $hostname -and $_.rData -eq $TxtValue})) {
        Write-Verbose "Matching record found... deleting"
        $DeleteResponse = Invoke-RestMethod -Uri "$($URI)/zones/records/$($domain)/$($zRecord.id)?format=json" -ContentType 'application/json' -Headers $Headers -Method Delete @script:UseBasic
    }
    <#
    .SYNOPSIS
        Remove a DNS TXT record to EasyDNS.

    .DESCRIPTION
        Remove a DNS TXT record to EasyDNS.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER edToken
        The EasyDNS API Token.

    .PARAMETER edKey
        The EasyDNS API Key.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtEasyDNS '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'dfasdasf3j42f' 'adsfj834sadfda'

        Removes a TXT record for the specified site with the specified value.
    #>
}

Function Save-DnsTxtEasyDNS{
param([Parameter(ValueFromRemainingArguments)] $ExtraParams)
    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}