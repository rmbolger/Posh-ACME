function Get-DnsPluginHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Plugin,
        [Parameter(Mandatory,Position=1)]
        [ValidateSet('Add','Remove','Save')]
        [string]$Action,
        [Parameter(ParameterSetName='FullOrDefault')]
        [switch]$Full,
        [Parameter(ParameterSetName='Detailed',Mandatory)]
        [switch]$Detailed,
        [Parameter(ParameterSetName='Examples',Mandatory)]
        [switch]$Examples,
        [Parameter(ParameterSetName='Parameter',Mandatory)]
        [string]$Parameter,
        [Parameter(ParameterSetName='ShowWindow',Mandatory)]
        [switch]$ShowWindow
    )

    # dot source the plugin file
    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'DnsPlugins'
    . (Join-Path $pluginDir "$Plugin.ps1")

    # build the command name
    $cmd = "$Action-DnsTxt$Plugin"

    switch ($PSCmdlet.ParameterSetName) {
        'FullOrDefault' {
            if ($Full) { Get-Help $cmd -Full }
            else { Get-Help $cmd }
            break
        }
        'Detailed' { Get-Help $cmd -Detailed; break }
        'Examples' { Get-Help $cmd -Examples; break }
        'Parameter' { Get-Help $cmd -Parameter $Parameter; break }
        'ShowWindow' { Get-Help $cmd -ShowWindow; break }
    }





    <#
    .SYNOPSIS
        List the available DNS plugins

    .DESCRIPTION
        The returned values are what should be used with the -DnsPlugin argument on various other functions.

    .EXAMPLE
        Get-DnsPlugins

        Get the list of available DnsPlugins

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-DnsPlugins

    .LINK
        New-PACertificate

    .LINK
        Publish-DnsChallenge

    #>
}
