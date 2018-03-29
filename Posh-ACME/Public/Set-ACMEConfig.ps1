function Set-ACMEConfig {
    [CmdletBinding(DefaultParameterSetName='WellKnown')]
    param(
        [Parameter(ParameterSetName='WellKnown')]
        [ValidateSet('LE_PROD','LE_STAGE')]
        [string]$WellKnownACMEServer='LE_STAGE',
        [Parameter(ParameterSetName='Custom')]
        [string]$CustomACMEServer,
        [pscustomobject]$AccountKey,
        [string]$AccountUri
    )

    $SaveChanges = $false

    if ('WellKnownACMEServer' -in $PSBoundParameters.Keys -or 'CustomACMEServer' -in $PSBoundParameters.Keys) {
        # grab the appropriate directory URI
        if ($PSCmdlet.ParameterSetName -eq 'WellKnown') {
            $DirUrl = $script:WellKnownDirs[$WellKnownACMEServer]
        } else {
            $DirUrl = $CustomACMEServer
        }

        if ($script:cfg.CurrentDir -ne $DirUrl) {
            $script:cfg.CurrentDir = $DirUrl
            $SaveChanges = $true
        }

        # create the config entry for this Uri if it doesn't exist
        if (!$script:cfg.$DirUrl) {
            $newcfg = [pscustomobject]@{
                AccountAlg = [string]::Empty;
                AccountUri = [string]::Empty;
                AccountKey = @{};
            }
            $script:cfg | Add-Member -MemberType NoteProperty -Name $DirUrl -Value $newcfg
            $SaveChanges = $true
        }

    } elseif ([string]::IsNullOrWhiteSpace($script:cfg.CurrentDir)) {
        throw "No ACME Server specified and no saved value found."
    }

    # make a variable shortcut to the current server's config
    $curcfg = $script:cfg.($script:cfg.CurrentDir)

    # deal with account key changes
    if ($AccountKey) {

        # make sure it's valid before saving it
        try { $AccountKey | ConvertFrom-Jwk -EA Stop | Out-Null }
        catch { throw 'Invalid AccountKey' }

        # don't bother saving it unless it's different than the old one
        if (($AccountKey | ConvertTo-Json -Compress) -ne ($curcfg.AccountKey | ConvertTo-Json -Compress)) {

            $curcfg.AccountKey = $AccountKey
            $SaveChanges = $true

            # make sure AccountAlg matches
            $curcfg.AccountAlg = (Get-JwsAlg $AccountKey)

            # new account key means the other account metadata is no longer valid
            # so wipe it
            $curcfg.AccountUri = [string]::Empty
            $curcfg.Account = [pscustomobject]@{}
        }

    }

    if ($AccountUri) {
        # there's not much to validate here, so just make sure it's different than the old one
        if ($AccountUri -ne $curCfg.AccountUri) {
            $curCfg.AccountUri = $AccountUri
            $SaveChanges = $true
        }
    }





    if ($SaveChanges) {
        # write the config to disk
        $script:cfg | ConvertTo-Json | Out-File $script:ConfigFile -Encoding UTF8
    }

}
