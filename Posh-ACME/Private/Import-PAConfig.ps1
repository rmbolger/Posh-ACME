function Import-PAConfig {
    [CmdletBinding()]
    param(
    )

    # The config structure looks like this:
    # %LOCALAPPDATA%\Posh-ACME
    # - current-server.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)
    # - current-account.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)\(account)
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
    $script:DirUrl = Get-Content (Join-Path $script:ConfigRoot 'current-server.txt') -ErrorAction SilentlyContinue
    if (![string]::IsNullOrWhiteSpace($script:DirUrl)) {

        $script:DirUrlFolder = Convert-DirToFolder $script:DirUrl
        Update-PAServer $script:DirUrl

        # load the current account into memory if it exists on disk
        $AcctID = Get-Content (Join-Path $script:DirUrlFolder 'current-account.txt') -ErrorAction SilentlyContinue
        if (![string]::IsNullOrWhiteSpace($AcctID)) {

            $script:AcctFolder = Join-Path $script:DirUrlFolder $AcctID
            $script:Acct = Get-Content (Join-Path $script:AcctFolder 'acct.json') -Raw | ConvertFrom-Json
            $script:Acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

        }
    }

}
