function Publish-Challenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=2)]
        [string]$Token,
        [Parameter(Mandatory,Position=3)]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string]$Plugin,
        [Parameter(Position=4)]
        [hashtable]$PluginArgs,
        [string]$DnsAlias
    )

    # dot source the plugin file
    $pluginDetail = $script:Plugins.$Plugin
    . $pluginDetail.Path

    # All plugins in $script:Plugins should have been validated during module
    # load. So we're not going to do much plugin-specific validation here.
    Write-Verbose "Publishing challenge for Domain $Domain with Token $Token using Plugin $Plugin and DnsAlias '$DnsAlias'."

    # sanitize the $Domain if it was passed in as a wildcard on accident
    if ($Domain -and $Domain.StartsWith('*.')) {
        Write-Warning "Stripping wildcard characters from domain name. Not required for publishing."
        $Domain = $Domain.Substring(2)
    }

    # do stuff appropriate for the challenge type
    if ('dns-01' -eq $pluginDetail.ChallengeType) {

        # determine the appropriate record name
        if (-not [String]::IsNullOrWhiteSpace($DnsAlias)) {
            # always use the alias if it was specified
            $recordName = $DnsAlias
        } else {
            # use Domain
            $recordName = "_acme-challenge.$($Domain)"
        }

        $txtValue = Get-KeyAuthorization $Token $Account -ForDNS

        # call the function with the required parameters and splatting the rest
        Write-Debug "Calling $Plugin plugin to add $recordName TXT with value $txtValue"
        Add-DnsTxt -RecordName $recordName -TxtValue $txtValue @PluginArgs

    } else { # http-01 is the only other challenge type we support at the moment

        $keyAuth = Get-KeyAuthorization $Token $Account

        # call the function with the required parameters and splatting the rest
        Write-Debug "Calling $Plugin plugin to add challenge for $Domain with token $Token and key auth $keyAuth"
        Add-HttpChallenge -Domain $Domain -Token $Token -Body $keyAuth @PluginArgs

    }
}
