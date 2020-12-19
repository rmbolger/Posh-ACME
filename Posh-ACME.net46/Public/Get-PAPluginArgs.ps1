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
        try {
            # Make sure we have an account configured
            if (-not ($acct = Get-PAAccount)) {
                throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
            }
        }
        catch { $PSCmdlet.ThrowTerminatingError($_) }

        function SecureDeserialize {
            [CmdletBinding()]
            param(
                [object]$SafeVal,
                [hashtable]$EncParam
            )

            if ($SafeVal -is [pscustomobject]) {
                if ($SafeVal.origType) {
                    if ('pscredential' -eq $SafeVal.origType) {
                        return [pscredential]::new(
                            $SafeVal.user,($SafeVal.pass | ConvertTo-SecureString @EncParam)
                        )
                    }
                    elseif ('securestring' -eq $SafeVal.origType) {
                        return $SafeVal.value | ConvertTo-SecureString @EncParam
                    }
                } else {
                    Write-Debug "PluginArg deserialized as custom object we don't recognize. Treating as hashtable."
                    # We're going to assume all custom objects that don't have an 'origType' property
                    # were hashtables that we can safely convert back.
                    $subHT = @{}
                    foreach ($subprop in $SafeVal.PSObject.Properties) {
                        $subHT[$subprop.Name] = $subprop.Value
                    }
                    return $subHT
                }
            }
            elseif ($SafeVal -is [array]) {
                $converted = foreach ($val in $SafeVal) { SecureDeserialize $val $EncParam }
                return $converted
            }
            else {
                return $SafeVal
            }
        }
    }

    Process {
        trap { $PSCmdlet.WriteError($_); return }

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

            # get the encryption parameter
            $encParam = Get-EncryptionParam -Account $acct -EA Stop

            # Convert it to a hashtable and do our custom deserialization on SecureString
            # and PSCredential objects.
            foreach ($prop in $pDataSafe.PSObject.Properties) {
                $pData[$prop.Name] = SecureDeserialize $prop.Value $encParam
            }
        }

        $pData
    }
}
