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
        [hashtable]$ACMERegistration,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Each name used with AcmeDns must be dynamically registered with the acme-dns
    # server and a CNAME record created by the user based on the registration before
    # proceeding. Each registration needs to be saved so it can be re-used later without
    # the user needing to explicitly pass it in.

    # So we're going to use the new Import/Export-PluginVar functions but we also need to
    # allow for importing the legacy ACMEReg value from plugindata.xml that will no longer
    # be passed in.
    if (-not ($ACMEReg = Import-PluginVar ACMEReg)) {
        # check for legacy registration data by getting all saved pluginargs on this account
        # which should include AcmeReg if it still exists
        $pargs = Import-PluginArgs
        if ($pargs.ACMEReg) {
            # Convert the hashtable to JSON and back to basically make it PSCustomObject
            # which the rest of the plugin is now expecting
            Write-Verbose "Migrating legacy acme-dns registrations"
            $ACMEReg = $pargs.ACMEReg | ConvertTo-Json | ConvertFrom-Json
        } else {
            # no existing data, so create an empty object to use
            Write-Verbose "No existing acme-dns registrations found"
            $ACMEReg = [pscustomobject]@{}
        }
    }

    # Add or override existing registrations with passed in registrations
    if ($ACMERegistration) {
        foreach ($fqdn in $ACMERegistration.Keys) {
            if ($fqdn -notin $ACMEReg.PSObject.Properties.Name) {
                Write-Debug "Adding passed in registration for $fqdn"
                $ACMEReg | Add-Member $fqdn $ACMERegistration.$fqdn
            } else {
                Write-Debug "Overwriting saved registration with passed in value for $fqdn"
                $ACMEReg.$fqdn = $ACMERegistration.$fqdn
            }
        }

        # save the new registration(s)
        Export-PluginVar ACMEReg $ACMEReg
    }

    # create a new subdomain registration if necessary
    if ($RecordName -notin $ACMEReg.PSObject.Properties.Name) {
        $reg = New-AcmeDnsRegistration $ACMEServer $ACMEAllowFrom

        $ACMEReg | Add-Member $RecordName @($reg.subdomain,$reg.username,$reg.password,$reg.fulldomain)

        # we need to notify the user to create a CNAME for this registration
        # so save it to memory to display later during Save-DnsTxtAcmeDns
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
