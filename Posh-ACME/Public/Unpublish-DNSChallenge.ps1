function Unpublish-DnsChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=2)]
        [string]$Token,
        [Parameter(Mandatory,Position=3)]
        [string]$Plugin,
        [Parameter(Position=4)]
        [hashtable]$PluginArgs,
        [switch]$NoPrefix
    )

    if ($NoPrefix) {
        $recordName = $Domain
    } else {
        $recordName = "_acme-challenge.$Domain"
    }

    $keyAuth = Get-KeyAuthorization $Token $Account

    # hash and encode the key authorization value
    $keyAuthBytes = [Text.Encoding]::UTF8.GetBytes($keyAuth)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $keyAuthHash = $sha256.ComputeHash($keyAuthBytes)
    $txtValue = ConvertTo-Base64Url $keyAuthHash

    Write-Debug "Calling $Plugin plugin to remove $recordName TXT with value $txtValue"

    # dot source the plugin file
    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'
    . (Join-Path $pluginDir "$Plugin.ps1")

    # check for the command that should exist now based on plugin name
    $delCommand = "Remove-DnsTxt$Plugin"
    if (!(Get-Command $delCommand -ErrorAction SilentlyContinue)) {
        throw "Expected plugin command $delCommand not found."
    }

    # call the function with the required parameters and splatting the rest
    &$delCommand $recordName $txtValue @PluginArgs





    <#
    .SYNOPSIS
        Unpublish the TXT record for a dns-01 authorization challenge.

    .DESCRIPTION
        Uses one of the DNS plugins and its associated parameters to remove a TXT record from DNS that satisfies the dns-01 authorization challenge in an ACME order.

        Depending on the plugin, calling Save-DnsChallenge may be required to commit changes to the DNS server. If multiple challenges are being unpublished, make all Unpublish-DnsChallenge calls first. Then, Save-DnsChallenge once to commit them all.

    .PARAMETER Domain
        The domain name that the TXT record will be removed from.

    .PARAMETER Account
        The account object associated with the order that required the challenge.

    .PARAMETER Token
        The DNS01Token value from the authorization object in the order.

    .PARAMETER Plugin
        The name of the DNS plugin to use. Use Get-DnsPlugins to display a list of available plugins.

    .PARAMETER PluginArgs
        A hashtable containing the plugin arguments to use with the specified DnsPlugin list. So if a plugin has a -MyText string and -MyNumber integer parameter, you could specify them as @{MyText='text';MyNumber=1234}.

    .PARAMETER NoPrefix
        If specified, '_acme-challenge.' will not be added to record name being written in DNS. This normally only used when using challenge aliases.

    .EXAMPLE
        $auths = Get-PAOrder | Get-PAAuthorizations
        PS C:\>Unpublish-DnsChallenge $auths[0].fqdn (Get-PAAccount) $auths[0].DNS01Token Manual @{}

        Unpublish the DNS challenge for the first authorization in the current order using the Manual DNS plugin.

    .EXAMPLE
        $auths = Get-PAOrder | Get-PAAuthorizations
        PS C:\>$acct = Get-PAAccount
        PS C:\>$auths | %{ Unpublish-DnsChallenge $_.fqdn $acct $_.DNS01Token Flurbog @{FBServer='127.0.0.1';FBToken='abc123'} }

        Unpublish all DNS challenges for the current order using the Flurbog DNS plugin.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Publish-DnsChallenge

    .LINK
        Save-DnsChallenge

    .LINK
        Get-DnsPlugins

    .LINK
        Get-DnsPluginHelp

    #>
}
