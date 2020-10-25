function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ACMEServer,
        [string[]]$ACMEAllowFrom,
        [hashtable]$ACMERegistration,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Each name used with AcmeDns must be dynamically registered with the acme-dns
    # server and a CNAME record created by the user based on the registration before
    # proceeding. Each registration needs to be saved so it can be re-used later without
    # the user needing to explicitly pass it in.
    if (-not ($ACMEReg = Import-PluginVar ACMEReg)) {
        # no existing data, so create an empty object to use
        Write-Verbose "No existing acme-dns registrations found"
        $ACMEReg = [pscustomobject]@{}
    }

    # Add or override existing registrations with passed in registrations
    if ($ACMERegistration) {
        foreach ($fqdn in $ACMERegistration.Keys) {
            Write-Debug "Adding passed in registration for $fqdn"
            $ACMEReg | Add-Member $fqdn $ACMERegistration.$fqdn -Force
        }

        # save the new registration(s)
        Export-PluginVar ACMEReg $ACMEReg
    }

    # create a new subdomain registration if necessary
    if ($RecordName -notin $ACMEReg.PSObject.Properties.Name) {
        $reg = New-AcmeDnsRegistration $ACMEServer $ACMEAllowFrom

        $ACMEReg | Add-Member $RecordName @($reg.subdomain,$reg.username,$reg.password,$reg.fulldomain)

        # we need to notify the user to create a CNAME for this registration
        # so save it to memory to display later during Save-DnsTxt
        if (!$script:ACMECNAMES) { $script:ACMECNAMES = @() }
        $script:ACMECNAMES += [pscustomobject]@{Record=$RecordName;CNAME=$reg.fulldomain}

        # save the new registration
        Export-PluginVar ACMEReg $ACMEReg
    }

    # grab a reference to this record's registration values
    $regVals = $ACMEReg.$RecordName

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

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'xxxxxxxx' 'auth.acme-dns.io'

        Adds a TXT record for the specified site with the specified value and no IP filtering.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'xxxxxxxx' 'auth.acme-dns.io' -ACMEAllowFrom "192.168.100.1/24","2002:c0a8:2a00::0/40"

        Adds a TXT record for the specified site with the specified value and only allowed from the specified networks.
    #>
}

function Remove-DnsTxt {
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

function Save-DnsTxt {
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
        If new acme-dns registrations have previously been made with Add-DnsTxt, the CNAMEs need to be created by the user before challenge validation will succeed. This function outputs any pending CNAMEs to be created and then waits for user confirmation to continue.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

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
