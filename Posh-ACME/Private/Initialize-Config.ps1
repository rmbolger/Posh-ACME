function Initialize-Config {
    [CmdletBinding()]
    param()

    # setup some module wide variables
    $script:WellKnownDirs = @{
        LE_PROD = 'https://acme-v02.api.letsencrypt.org/directory';
        LE_STAGE = 'https://acme-staging-v02.api.letsencrypt.org/directory';
    }
    $script:HEADER_NONCE = 'Replay-Nonce'
    $script:NextNonce = ''
    $script:UserAgent = "Posh-ACME/0.1 PowerShell/$($PSVersionTable.PSVersion)"
    $script:CommonHeaders = @{'Accept-Language'='en-us,en;q=0.5'}
    $script:ContentType = 'application/jose+json'

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
    $script:ConfigRoot = Join-Path $env:LOCALAPPDATA 'Posh-ACME'
    if (!(Test-Path $script:ConfigRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $script:ConfigRoot -Force | Out-Null
    }

    # load the current directory into memory if it exists on disk
    $script:CurrentDir = Get-Content (Join-Path $script:ConfigRoot 'current-server.txt') -ErrorAction SilentlyContinue
    if (![string]::IsNullOrWhiteSpace($script:CurrentDir)) {

        $script:CurrentDirFolder = Convert-DirToFolder $script:CurrentDir
        Update-PAServer $script:CurrentDir

        # load the current account into memory if it exists on disk
        $curAcctID = Get-Content (Join-Path $script:CurrentDirFolder 'current-account.txt') -ErrorAction SilentlyContinue
        if (![string]::IsNullOrWhiteSpace($curAcctID)) {

            $script:CurrentAccountFolder = Join-Path $script:CurrentDirFolder $curAcctID
            $script:CurrentAccount = Get-Content (Join-Path $script:CurrentAccountFolder 'acct.json') -Raw | ConvertFrom-Json
            $script:CurrentAccount.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

        }
    }

}