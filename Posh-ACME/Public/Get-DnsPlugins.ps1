function Get-DnsPlugins {
    [CmdletBinding()]
    [OutputType('System.String')]
    param()

    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'

    (Get-ChildItem (Join-Path $pluginDir *.ps1) -Exclude '_Example.ps1').BaseName | Sort-Object





    <#
    .SYNOPSIS
        List the available DNS plugins

    .DESCRIPTION
        The returned values are what should be used with the -DnsPlugin parameter on various other functions.

    .EXAMPLE
        Get-DnsPlugins

        Get the list of available DnsPlugins

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    .LINK
        Publish-DnsChallenge

    .LINK
        Get-DnsPluginHelp

    #>
}
