function Get-PAPluginArgs {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-ValidFriendlyName $_ -ThrowOnFail})]
        [string]$Name
    )

    Begin {
        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {
        trap { $PSCmdlet.ThrowTerminatingError($PSItem) }

        # try to find an order using the specified parameters
        $order = Get-PAOrder @PSBoundParameters

        if (-not $order) {
            if (-not $MainDomain -and -not $Name) {
                Write-Warning "No ACME order configured. Run Set-PAOrder or New-PAOrder first."
            } else {
                Write-Warning "No ACME order found using the specified parameters."
            }
            return @{}
        }

        $pDataFile = Join-Path $order.Folder 'pluginargs.json'
        $pData = @{}

        if (Test-Path $pDataFile -PathType Leaf) {

            # Despite being exported as a hashtable, it comes back in as a PSCustomObject
            # And while there's -AsHashtable in PS 6+, we can't rely on it until we
            # drop support for PS 5.1.
            $pDataSafe = Get-Content $pDataFile -Raw -Encoding utf8 -EA Ignore | ConvertFrom-Json

            # determine whether we're using a custom key
            $encParam = @{}
            if (-not [String]::IsNullOrEmpty($acct.sskey)) {
                $encParam.Key = $acct.sskey | ConvertFrom-Base64Url -AsByteArray
            }

            # Convert it to a hashtable and do our custom deserialization on SecureString
            # and PSCredential objects.
            foreach ($prop in $pDataSafe.PSObject.Properties) {
                if ($prop.TypeNameOfValue -eq 'System.Management.Automation.PSCustomObject') {
                    if ($prop.Value.origType) {
                        if ('pscredential' -eq $prop.Value.origType) {
                            $pData[$prop.Name] = [pscredential]::new(
                                $prop.Value.user,($prop.Value.pass | ConvertTo-SecureString @encParam)
                            )
                        }
                        elseif ('securestring' -eq $prop.Value.origType) {
                            $pData[$prop.Name] = $prop.Value.value | ConvertTo-SecureString @encParam
                        }
                    }
                    else {
                        Write-Debug "PluginArg $($prop.Name) deserialized as custom object we don't recognize. Treating as hashtable."
                        # We're going to assume all custom objects that don't have an 'origType' property
                        # were hashtables that we can safely convert back.
                        $subHT = @{}
                        foreach ($subprop in $prop.Value.PSObject.Properties) {
                            $subHT[$subprop.Name] = $subprop.Value
                        }
                        $pData[$prop.Name] = $subHT
                    }
                }
                else {
                    $pData[$prop.Name] = $prop.Value
                }
            }
        }

        $pData
    }

    <#
    .SYNOPSIS
        Retrieve the plugin args for the current or specified order.

    .DESCRIPTION
        An easy way to recall the plugin args used for a given order.

    .PARAMETER MainDomain
        The primary domain for the order. For a SAN order, this was the first domain in the list when creating the order.

    .PARAMETER Name
        The name of the ACME order. This can be useful to distinguish between two orders that have the same MainDomain.

    .EXAMPLE
        Get-PAPluginArgs

        Retrieve the plugin args for the current order.

    .EXAMPLE
        Get-PAPluginArgs -Name myorder

        Retrieve the plugin args for the specified order.

    .EXAMPLE
        Get-PAOrder -Name myorder | Get-PAPluginArgs

        Retrieve the plugin args for the order passed via the pipeline.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Gew-PAOrder
    #>
}
