function Get-PAPlugin {
    [CmdletBinding(DefaultParameterSetName='Basic')]
    param(
        [Parameter(ParameterSetName='Basic', Position=0)]
        [Parameter(ParameterSetName='Help', Position=0, Mandatory)]
        [Parameter(ParameterSetName='Guide', Position=0, Mandatory)]
        [Parameter(ParameterSetName='Params', Position=0, Mandatory)]
        [ValidateScript({Test-ValidPlugin $_ -ThrowOnFail})]
        [string]$Plugin,
        [Parameter(ParameterSetName='Help', Mandatory)]
        [switch]$Help,
        [Parameter(ParameterSetName='Guide', Mandatory)]
        [switch]$Guide,
        [Parameter(ParameterSetName='Params', Mandatory)]
        [switch]$Params
    )

    # return the list of plugin details if a specific plugin wasn't specified
    if ([String]::IsNullOrWhiteSpace($Plugin)) {
        $script:Plugins.Values | Sort-Object Name
        return
    }

    $pluginDetail = $script:Plugins.$Plugin

    if ('Basic' -eq $PSCmdlet.ParameterSetName) {
        # return specific plugin details
        return $pluginDetail
    }

    # dot source the plugin
    . $pluginDetail.Path

    # get a reference to the associated add command
    if ('dns-01' -eq $pluginDetail.ChallengeType) {
        $cmd = Get-Command Add-DnsTxt
    } else {
        $cmd = Get-Command Add-HttpChallenge
    }

    if ('Params' -eq $PSCmdlet.ParameterSetName) {

        # define the set of parameter names to ignore
        $ignoreParams = @('RecordName','TxtValue','Domain','Token','Body') + [Management.Automation.PSCmdlet]::CommonParameters +
            [Management.Automation.PSCmdlet]::OptionalCommonParameters

        # Now we want to make a flattened list of parameters that are tagged with
        # their associated parameter set data to enable our custom output formatting
        $paramFlatList = foreach ($set in $cmd.ParameterSets) {

            $setParams = $set.Parameters | Where-Object {
                $_.Name -notin $ignoreParams -and
                $true -notin $_.Attributes.ValueFromRemainingArguments
            }

            $setParams | ForEach-Object {

                $setName = $set.Name
                if ($setName -eq '__AllParameterSets') {
                    $setName = '(Default)'
                }

                [pscustomobject]@{
                    PSTypeName = 'PoshACME.PluginParameter'
                    ParameterSet = $setName
                    IsDefault = $set.IsDefault
                    Parameter = $_.Name
                    ParameterType = $_.ParameterType
                    IsMandatory = $_.IsMandatory
                }
            }
        }
        return $paramFlatList
    }

    elseif ('Guide' -eq $PSCmdlet.ParameterSetName) {
        # Currently opening a browser this way only works on Windows, but we're
        # tracking this issue for potentially better cross-platform solutions in
        # the future.
        # https://github.com/PowerShell/PowerShell/issues/7201

        $url = "https://github.com/rmbolger/Posh-ACME/blob/main/Posh-ACME/Plugins/$($pluginDetail.Name)-Readme.md"

        try {
            # launch the browser to the guide
            Start-Process $url
        } catch {
            # just return the URL
            $url
        }
        return
    }

    elseif ('Help' -eq $PSCmdlet.ParameterSetName) {

        if ('dns-01' -eq $pluginDetail.ChallengeType) {
            Get-Help Add-DnsTxt
        } else {
            Get-Help Add-HttpChallenge
        }
        return
    }



    <#
    .SYNOPSIS
        Show plugin details, help, or launch the online guide.

    .DESCRIPTION
        With no parameters, this function will return a list of built-in validation plugins and their details.

        With a Plugin specified, this function will return that plugin's details, help, or launch the online guide depending on which switches are specified.

    .PARAMETER Plugin
        The name of a validation plugin.

    .PARAMETER Help
        If specified, display the help contents for the specified plugin.

    .PARAMETER Guide
        If specified, launch the default web browser to the specified plugin's online guide. This currently only works on Windows and will simply display the URL on other OSes.

    .PARAMETER Params
        If specified, returns the plugin-specific parameter sets associated with this plugin.

    .EXAMPLE
        Get-PAPlugin

        Get the list of available validation plugins

    .EXAMPLE
        Get-PAPlugin Route53 -Guide

        Launch the user's default web browser to the online guide for the specified plugin.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        New-PACertificate

    .LINK
        Publish-Challenge

    #>
}
