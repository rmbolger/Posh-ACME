function Add-DnsTxtAcmeDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ACMEServer,
        [string[]]$ACMEAllowFrom,
        [hashtable]$ACMEReg,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Because we're doing acme-dns registrations on demand for new names, even if
    # the $ACMEReg variable was passed in, it may not reflect the true current state
    # because Submit-ChallengeValidation doesn't re-import PluginArgs between calls
    # to Publish-DnsChallenge. Since we know there might be updated values, we need
    # to explicitly re-import PluginArgs here to get the most up to date version and
    # basically ignore the passed in $ACMEReg object.
    $pargs = Merge-PluginArgs

    # If an existing ACMEReg wasn't passed in, create a new one to store new registrations
    if (!$pargs.ACMEReg) { $pargs.ACMEReg = @{} }

    # create a new subdomain registration if necessary
    if ($RecordName -notin $pargs.ACMEReg.Keys) {
        $reg = New-AcmeDnsRegistration $ACMEServer $ACMEAllowFrom
        $pargs.ACMEReg.$RecordName = @($reg.subdomain,$reg.username,$reg.password,$reg.fulldomain)

        # we need to notify the user to create a CNAME for this registration
        # so save it to memory to display later during Save-DnsTxtAcmeDns
        if (!$script:ACMECNAMES) { $script:ACMECNAMES = @() }
        $script:ACMECNAMES += [pscustomobject]@{Record=$RecordName;CNAME=$reg.fulldomain}

        # merge and save the updated PluginArgs
        Merge-PluginArgs $pargs | Out-Null
    }

    # grab a reference to this record's registration values
    $regVals = $pargs.ACMEReg.$RecordName

    # create the auth header object
    $authHead = @{'X-Api-User'=$regVals[1];'X-Api-Key'=$regVals[2]}

    # create the update body
    $updateBody = @{subdomain=$regVals[0];txt=$TxtValue} | ConvertTo-Json -Compress

    # send the update
    try {
        Write-Verbose "Updating $($regVals[3]) with $TxtValue"
        $response = Invoke-RestMethod "https://$ACMEServer/update" -Method Post `
            -Headers $authHead -Body $updateBody @script:UseBasic
        Write-Debug ($response | ConvertTo-Json)
    } catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to acme-dns.

    .DESCRIPTION
        This plugin requires using the -DnsAlias option. The value for DnsAlias is the "fulldomain" returned by the acme-dns register endpoint.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ACMEServer
        The FQDN of the acme-dns server instance.

    .PARAMETER ACMEAllowFrom
        A list of networks in CIDR notation that the acme-dns server should allow updates from. If not specified, the acme-dns server will not block any updates based on IP address.

    .PARAMETER ACMEReg
        A hashtable of existing acme-dns registrations. This parameter is managed by the plugin and you shouldn't ever need to specify it manually.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxtAcmeDns '_acme-challenge.site1.example.com' 'xxxxxxxxxxXXXXXXXXXXxxxxxxxxxxXXXXXXXXXX001' 'auth.acme-dns.io'

        Adds a TXT record for the specified site with the specified value and no IP filtering.

    .EXAMPLE
        Add-DnsTxtAcmeDns '_acme-challenge.site1.example.com' 'xxxxxxxxxxXXXXXXXXXXxxxxxxxxxxXXXXXXXXXX001' 'auth.acme-dns.io' @('192.168.100.1/24","2002:c0a8:2a00::0/40")

        Adds a TXT record for the specified site with the specified value and only allowed from the specified networks.
    #>
}

function Remove-DnsTxtAcmeDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to remove DNS TXT records.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

function Save-DnsTxtAcmeDns {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ($script:ACMECNAMES -and $script:ACMECNAMES.Count -gt 0) {

        Write-Host
        Write-Host "Please create the following CNAME records:"
        Write-Host "------------------------------------------"
        $script:ACMECNAMES | ForEach-Object {
            Write-Host "$($_.Record) -> $($_.CNAME)"
        }
        Write-Host "------------------------------------------"
        Write-Host

        # clear out the variable so we don't notify twice
        Remove-Variable ACMECNAMES -Scope Script

        Read-Host -Prompt "Press any key to continue." | Out-Null
    }

    <#
    .SYNOPSIS
        Returns CNAME records that must be created by the user.

    .DESCRIPTION
        If new acme-dns registrations have previously been made with Add-DnsTxtAcmeDns, the CNAMEs need to be created by the user before challenge validation will succeed. This function outputs any pending CNAMEs to be created and then waits for user confirmation to continue.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxtAcmeDns

        Displays pending CNAME records to create.
    #>
}

############################
# Helper Functions
############################

function New-AcmeDnsRegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ACMEServer,
        [Parameter(Position=1)]
        [string[]]$ACMEAllowFrom
    )

    # build the registration body
    if ($ACMEAllowFrom) {
        $regBody = @{allowfrom=$ACMEAllowFrom} | ConvertTo-Json -Compress
    } else {
        $regBody = '{}'
    }

    # do the registration
    try {
        Write-Verbose "Registering new subdomain on $ACMEServer"
        $reg = Invoke-RestMethod "https://$ACMEServer/register" -Method POST -Body $regBody `
            -ContentType 'application/json' @script:UseBasic
        Write-Debug ($reg | ConvertTo-Json)
    } catch { throw }

    # return the results
    return $reg
}
