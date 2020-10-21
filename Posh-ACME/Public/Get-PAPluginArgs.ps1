function Get-PAPluginArgs {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]$MainDomain
    )

    Begin {
        trap { $PSCmdlet.ThrowTerminatingError($PSItem) }

        # Make sure we have an account configured
        if (-not (Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    Process {
        trap { $PSCmdlet.ThrowTerminatingError($PSItem) }

        # throw an error if there's no current order and no MainDomain passed in
        if (-not $script:Order -and -not $MainDomain) {
            throw "No ACME order configured. Run Set-PAOrder, New-PAOrder, or specify a MainDomain."
        }

        # use the current order if something else wasn't specified
        if (-not $MainDomain) {
            $MainDomain = $script:Order.MainDomain
        } else {
            $WarnOnMissing = $true
        }

        $orderFolder = Join-Path $script:AcctFolder $MainDomain.Replace('*','!')
        $pDataFile = Join-Path $orderFolder 'pluginargs.json'
        $pData = @{}

        # write a warning if they specified an order and it doesn't exist
        if ($WarnOnMissing -and -not (Test-Path $orderFolder -PathType Container)) {
            Write-Warning "No order found for $MainDomain in $orderFolder"
        }

        if (Test-Path $pDataFile -PathType Leaf) {

            # Despite being exported as a hashtable, it comes back in as a PSCustomObject
            # And while there's  -AsHashtable in PS 6+, we can't rely on it until we
            # drop support for PS 5.1.
            $pDataSafe = Get-Content $pDataFile -Raw -Encoding utf8 -EA Ignore | ConvertFrom-Json

            # Convert it to a hashtable and do our custom deserialization on SecureString
            # and PSCredential objects.
            foreach ($prop in $pDataSafe.PSObject.Properties) {
                if ($prop.TypeNameOfValue -eq 'System.Management.Automation.PSCustomObject') {
                    if ($prop.Value.origType) {
                        if ('pscredential' -eq $prop.Value.origType) {
                            $pData[$prop.Name] = New-Object PSCredential $prop.Value.user,($prop.Value.pass | ConvertTo-SecureString)
                        }
                        elseif ('securestring' -eq $prop.Value.origType) {
                            $pData[$prop.Name] = $prop.Value.value | ConvertTo-SecureString
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
    #>
}
