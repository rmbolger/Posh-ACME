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
    $script:CurrentDirFolder = Convert-DirToFolder $script:CurrentDir


    # $script:ConfigFile = Join-Path $script:ConfigFolder 'posh-acme.json'

    # # Import the existing config if there is one
    # try {
    #     $cfg = Get-Content $script:ConfigFile -Encoding UTF8 -EA Stop | ConvertFrom-Json -EA Stop
    #     $script:cfg = $cfg
    # } catch {
    #     # throw a warning if the config file was found but just couldn't be parsed
    #     if (Test-Path $script:ConfigFile) {
    #         Write-Warning "Config file found but content is invalid. Creating new config."
    #         Move-Item $script:ConfigFile "$($script:ConfigFile).bad" -Force
    #     }

    #     # create a new config
    #     $script:cfg = [pscustomobject]@{
    #         CurrentDir = [string]::Empty
    #     }

    #     # write the config to disk
    #     $script:cfg | ConvertTo-Json | Out-File $script:ConfigFile -Encoding UTF8
    # }


}