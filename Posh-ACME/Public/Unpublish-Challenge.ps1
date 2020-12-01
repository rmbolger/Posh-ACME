function Unpublish-Challenge {
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
    Write-Verbose "Unpublishing challenge for Domain $Domain with Token $Token using Plugin $Plugin and DnsAlias '$DnsAlias'."

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
        Write-Debug "Calling $Plugin plugin to remove $recordName TXT with value $txtValue"
        Remove-DnsTxt -RecordName $recordName -TxtValue $txtValue @PluginArgs

    } else { # http-01 is the only other challenge type we support at the moment

        $keyAuth = Get-KeyAuthorization $Token $Account

        # call the function with the required parameters and splatting the rest
        Write-Debug "Calling $Plugin plugin to remove challenge for $Domain with token $Token and key auth $keyAuth"
        Remove-HttpChallenge -Domain $Domain -Token $Token -Body $keyAuth @PluginArgs

    }



    <#
    .SYNOPSIS
        Unpublish a challenge using the specified plugin.

    .DESCRIPTION
        Based on the type of validation plugin specified, this function will unpublish either a DNS TXT record or an HTTP challenge file for the given domain and token value that satisfies the dns-01 or http-01 challenge specification.

        Depending on the plugin, calling Save-Challenge may be required to commit changes made by Unpublish-Challenge. If multiple challenges are being unpublished, make all Unpublish-Challenge calls first. Then, Save-Challenge once to commit them all.

    .PARAMETER Domain
        The domain name that the challenge will be unpublished for. Wildcard domains should have the "*." removed and can only be used with DNS based validation plugins.

    .PARAMETER Account
        The account object associated with the order that required the challenge.

    .PARAMETER Token
        The token value from the appropriate challenge in an authorization object that matches the plugin type.

    .PARAMETER Plugin
        The name of the validation plugin to use. Use Get-PAPlugin to display a list of available plugins.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified plugin. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER DnsAlias
        When using DNS Alias support with DNS validation plugins, the alias domain that the TXT record will be removed from. This should be the complete FQDN including the '_acme-challenge.' prefix if necessary. This field is ignored for non-DNS validation plugins.

    .EXAMPLE
        $auths = Get-PAOrder | Get-PAAuthorization
        PS C:\>Unpublish-Challenge $auths[0].DNSId (Get-PAAccount) $auths[0].DNS01Token Manual @{}

        Unpublish a DNS challenge for the first authorization in the current order using the Manual DNS plugin.

    .EXAMPLE
        $pArgs = @{Param1='asdf';Param2=1234}
        PS C:\>$acct = Get-PAAccount
        PS C:\>Unpublish-Challenge example.com $acct MyPlugin $pArgs -Token faketoken

        Unpublish a challenge for example.com using a fictitious plugin and arguments.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Publish-Challenge

    .LINK
        Save-Challenge

    .LINK
        Get-PAPlugin

    #>
}
