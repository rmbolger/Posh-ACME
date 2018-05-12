function Add-DnsTxtCloudflare {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$CFAuthEmail,
        [Parameter(Mandatory,Position=3)]
        [string]$CFAuthKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $Split = $RecordName.Split("{.}")
    #$Split

    $Zone = "$($Split[-2]).$($Split[-1])"
    #$Zone

    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add("X-Auth-Email", "$CFAuthEmail")
    $Headers.Add("X-Auth-Key", "$CFAuthKey")

    #Get All Domains
    $AllDomains=invoke-restmethod  -method get -uri "https://api.cloudflare.com/client/v4/zones/?per_page=1000&order=type&direction=asc" -Headers $Headers
    #$AllDomains.result.name

    #Select Zone
    $Domain = $AllDomains.result | Where-Object {$_.name -eq "$Zone"}
    #$Domain

    #GET DNS Records for Zone
    $allrecords=invoke-restmethod  -method get -uri "https://api.cloudflare.com/client/v4/zones/$($domain.id)/dns_records?per_page=1000&order=type&direction=asc&match=all" -Headers $Headers

    #Check for existing record
    $rec = $allrecords.result | Where-Object {$_.content -eq "$TxtValue"}

    # add (if necessary) the new TXT value to the list
    if (!$rec)
    {
        $Body = @{
            type = "TXT"
            name = "$RecordName"
            content = "$TxtValue"
        }
        $JSONData = $Body | ConvertTo-Json

        $JSONResult = invoke-restmethod  -method Post -uri "https://api.cloudflare.com/client/v4/zones/$($domain.id)/dns_records"  -ContentType "application/json"  -Headers $Headers -Body $jsondata
    }


    <#
    .SYNOPSIS
        Add a DNS TXT record to Cloudflare

    .DESCRIPTION
        Use Cloudflare V4 api to add a TXT record to a Cloudflare DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CFAuthEmail
        The email address of the account used to connect to Cloudflare API

    .PARAMETER CFAuthKey
        The auth key of the account associated to the email address entered in the CFAuthEmail parameter.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'admin@example.com' 'xxxxxxxxxxxx'

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxtCloudflare {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$CFAuthEmail,
        [Parameter(Mandatory,Position=3)]
        [string]$CFAuthKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $Split = $RecordName.Split("{.}")
    #$Split

    $Zone = "$($Split[-2]).$($Split[-1])"
    #$Zone

    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add("X-Auth-Email", "$CFAuthEmail")
    $Headers.Add("X-Auth-Key", "$CFAuthKey")

    #Get All Domains
    $AllDomains=invoke-restmethod  -method get -uri "https://api.cloudflare.com/client/v4/zones/?per_page=1000&order=type&direction=asc" -Headers $Headers
    #$AllDomains.result.name

    #Select Zone
    $Domain = $AllDomains.result | Where-Object {$_.name -eq "$Zone"}
    #$Domain

    #GET DNS Records for Zone
    $allrecords=invoke-restmethod  -method get -uri "https://api.cloudflare.com/client/v4/zones/$($domain.id)/dns_records?per_page=1000&order=type&direction=asc&match=all" -Headers $Headers

    #Check for existing record
    $rec = $allrecords.result | Where-Object {$_.content -eq "$TxtValue"}

    # remove (if necessary) the new TXT value to the list
    if ($rec)
    {
        $JSONResult = invoke-restmethod  -method  Delete "https://api.cloudflare.com/client/v4/zones/$($domain.id)/dns_records/$($rec.id)"   -ContentType "application/json"  -Headers $Headers
    }


    <#
    .SYNOPSIS
        Remove a DNS TXT record from Cloudflare

    .DESCRIPTION
        Use Cloudflare V4 api to remove a TXT record to a Cloudflare DNS zone.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER CFAuthEmail
        The email address of the account used to connect to Cloudflare API

    .PARAMETER CFAuthKey
        The auth key of the account associated to the email address entered in the CFAuthEmail parameter.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxtExample '_acme-challenge.site1.example.com' 'asdfqwer12345678' 'admin@example.com' 'xxxxxxxxxxxx'

        Removes a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxtCloudflare {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do.  Cloudflare doesn't require a save step

    # Add DNS provider specific parameters before $ExtraParams. Make sure
    # their names are unique across all existing plugins. But make
    # sure common ones across this plugin are the same.

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, remove
    # the $MyAPIVar parameters and just leave the body empty.

    <#
    .SYNOPSIS
        Not required for Cloudflare.

    .DESCRIPTION
        Cloudflare does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
