function Set-ACMEConfig {
    [CmdletBinding(DefaultParameterSetName='WellKnown')]
    param(
        [Parameter(ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnownACMEServer='LE_STAGE',
        [Parameter(ParameterSetName='Custom')]
        [string]$CustomACMEServer
    )

    $SaveChanges = $false

    if ('WellKnownACMEServer' -in $PSBoundParameters.Keys -or 'CustomACMEServer' -in $PSBoundParameters.Keys) {
        # grab the appropriate directory URI
        if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
            $DirUri = $script:WellKnownDirs[$WellKnownACMEServer]
        } else {
            $DirUri = $CustomACMEServer
        }

        if ($script:cfg.CurrentDir -ne $DirUri) {
            $script:cfg.CurrentDir = $DirUri
            $SaveChanges = $true
        }

        # create the config entry for this Uri if it doesn't exist
        if (!$script:cfg.$DirUri) {
            $newcfg = [pscustomobject]@{
                Account = @{};
                AccountUri = [string]::Empty;
                AccountKey = @{};
            }
            $script:cfg | Add-Member -MemberType NoteProperty -Name $DirUri -Value $newcfg
            $SaveChanges = $true
        }

    } elseif ([string]::IsNullOrWhiteSpace($script:cfg.CurrentDir)) {
        throw "No ACME Server specified and no saved value found."
    }

    # make a variable shortcut to the current server's config
    $curcfg = $script:cfg.$script:CurrentDir



    if ($SaveChanges) {
        # write the config to disk
        $script:cfg | ConvertTo-Json | Out-File $script:ConfigFile -Encoding UTF8
    }

}
