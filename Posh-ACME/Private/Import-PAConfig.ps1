function Import-PAConfig {
    [CmdletBinding()]
    param(
    )

    # The config structure looks like this:
    # %LOCALAPPDATA%\Posh-ACME
    # - current-server.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)
    # - dir.json
    # - current-account.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)\(account)
    # - acct.json
    # - current-cert.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)\(account)\(cert)
    # - conf.json
    # - cert.cer/key/pfx/etc

    # make sure we have the root config folder
    if ([string]::IsNullOrWhiteSpace($script:ConfigRoot)) {
        $script:ConfigRoot = Join-Path $env:LOCALAPPDATA 'Posh-ACME'
        if (!(Test-Path $script:ConfigRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $script:ConfigRoot -Force | Out-Null
        }
    }

    # load the current ACME directory into memory if it exists on disk
    $script:DirUrl = [string](Get-Content (Join-Path $script:ConfigRoot 'current-server.txt') -ErrorAction SilentlyContinue)
    if (![string]::IsNullOrWhiteSpace($script:DirUrl)) {

        $dirFolder = $script:DirUrl.Replace('https://','').Replace(':','_')
        $script:DirFolder = Join-Path $script:ConfigRoot $dirFolder.Substring(0,$dirFolder.IndexOf('/'))
        $script:Dir = Get-Content (Join-Path $script:DirFolder 'dir.json') -Raw | ConvertFrom-Json
        $script:Dir.PSObject.TypeNames.Insert(0,'PoshACME.PAServer')

        # load the current account into memory if it exists on disk
        $AcctID = [string](Get-Content (Join-Path $script:DirFolder 'current-account.txt') -ErrorAction SilentlyContinue)
        if (![string]::IsNullOrWhiteSpace($AcctID)) {

            $script:AcctFolder = Join-Path $script:DirFolder $AcctID
            $script:Acct = Get-Content (Join-Path $script:AcctFolder 'acct.json') -Raw | ConvertFrom-Json
            $script:Acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

            # load the current order into memory if it exists on disk
            $domain = [string](Get-Content (Join-Path $script:AcctFolder 'current-order.txt') -ErrorAction SilentlyContinue)
            if (![string]::IsNullOrEmpty($domain)) {

                $script:OrderFolder = Join-Path $script:AcctFolder $domain.Replace('*','!')
                $script:Order = Get-Content (Join-Path $script:OrderFolder 'order.json') -Raw | ConvertFrom-Json
                $script:Order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')

            }

        }
    }

}
