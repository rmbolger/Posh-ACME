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
    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'Plugins'
    . (Join-Path $pluginDir "$Plugin.ps1")

    # get the validation type
    if (-not (Get-Command 'Get-CurrentPluginType' -EA Ignore)) {
        throw 'Plugin is missing Get-CurrentPluginType function. Unable to continue.'
    }
    if (($chalType = Get-CurrentPluginType) -notin 'dns-01','http-01') {
        throw 'Plugin sent unrecognized challenge type.'
    }

    # sanitize the $Domain if it was passed in as a wildcard on accident
    if ($Domain -and $Domain.StartsWith('*.')) {
        Write-Warning "Stripping wildcard characters from domain name. Not required for publishing."
        $Domain = $Domain.Substring(2)
    }

    # do stuff appropriate for the challenge type
    if ('dns-01' -eq $chalType) {

        # check for the Add command that should exist now from the plugin
        if (-not (Get-Command 'Add-DnsTxt' -EA Ignore)) {
            throw "Plugin is missing Add-DnsTxt function. Unable to continue."
        }

        # determine the appropriate record name
        if (-not [String]::IsNullOrWhiteSpace($DnsAlias)) {
            # always use the alias if it was specified
            $recordName = $DnsAlias
        } else {
            # use Domain
            $recordName = "_acme-challenge.$($Domain)"
        }

        $txtValue = Get-KeyAuthorization $Token $Account -ForDNS

        Write-Debug "Calling $Plugin plugin to add $recordName TXT with value $txtValue"

        # call the function with the required parameters and splatting the rest
        Add-DnsTxt -RecordName $recordName -TxtValue $txtValue @PluginArgs

    } else { # http-01 is the only other challenge type we support at the moment

        # check for the Add command that should exist now from the plugin
        if (-not (Get-Command 'Add-HttpChallenge' -EA Ignore)) {
            throw "Plugin is missing Add-HttpChallenge function. Unable to continue."
        }

        $publishUrl = "http://$($Domain)/.well-known/acme-challenge/$($Token)"
        $keyAuth = Get-KeyAuthorization $Token $Account

        Write-Debug "Calling $Plugin to add $keyAuth body for challenge URL $publishUrl"

        # call the function with the required parameters and splatting the rest
        Add-HttpChallenge -Url $publishUrl -Body $keyAuth @PluginArgs

    }



    <#
    .SYNOPSIS
        Publish a challenge using the specified plugin.

    .DESCRIPTION
        Based on the type of validation plugin specified, this function will publish either a DNS TXT record or an HTTP challenge file for the given domain and token value that satisfies the dns-01 or http-01 challenge specification.

        Depending on the plugin, calling Save-Challenge may be required to commit changes made by Publish-Challenge. If multiple challenges are being published, make all Publish-Challenge calls first. Then, Save-Challenge once to commit them all.

    .PARAMETER Domain
        The domain name that the challenge will be published for. Wildcard domains should have the "*." removed and can only be used with DNS based validation plugins.

    .PARAMETER Account
        The account object associated with the order that requires the challenge.

    .PARAMETER Token
        The token value from the appropriate challenge in an authorization object that matches the plugin type.

    .PARAMETER Plugin
        The name of the validation plugin to use. Use Get-PAPlugin to display a list of available plugins.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified plugin. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER DnsAlias
        When using DNS Alias support with DNS validation plugins, the alias domain that the TXT record will be written to. This should be the complete FQDN including the '_acme-challenge.' prefix if necessary. This field is ignored for non-DNS validation plugins.

    .EXAMPLE
        $auths = Get-PAOrder | Get-PAAuthorizations
        PS C:\>Publish-Challenge $auths[0].DNSId (Get-PAAccount) $auths[0].DNS01Token Manual @{}

        Publish a DNS challenge for the first authorization in the current order using the Manual DNS plugin.

    .EXAMPLE
        $pArgs = @{Param1='asdf';Param2=1234}
        PS C:\>$acct = Get-PAAccount
        PS C:\>Publish-Challenge example.com $acct MyPlugin $pArgs -Token faketoken

        Publish a challenge for example.com using a fictitious plugin and arguments.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Unpublish-Challenge

    .LINK
        Save-Challenge

    .LINK
        Get-PAPlugin

    #>
}
