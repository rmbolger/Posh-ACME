function Import-PAConfig {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateSet('Server','Account','Order')]
        [string]$Level
    )

    # The config structure looks like this:
    # %LOCALAPPDATA%\Posh-ACME
    # - current-server.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)
    # - dir.json
    # - current-account.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)\(account)
    # - acct.json
    # - current-order.txt
    # %LOCALAPPDATA%\Posh-ACME\(server)\(account)\(order)
    # - order.json
    # - cert.cer/key/pfx/etc

    # Each level of the config is dependent on its parent. So if the user changes the server,
    # they need to reload the server and all of the child accounts and orders. But if they only
    # change the account, they only need to reload it and orders. And so on.

    # make sure we have the root config folder
    if ([string]::IsNullOrWhiteSpace((Get-ConfigRoot))) {
        if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
            Set-ConfigRoot (Join-Path $env:LOCALAPPDATA 'Posh-ACME')
        } elseif ($IsLinux) {
            Set-ConfigRoot (Join-Path $env:HOME '.config/Posh-ACME')
        } elseif ($IsMacOs) {
            Set-ConfigRoot (Join-Path $env:HOME 'Library/Preferences/Posh-ACME')
        } else {
            throw "Unrecognized PowerShell platform"
        }

        # allow overriding the default config location with a custom path
        # based on an the POSHACME_HOME environment variable
        if (-not [string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
            if (Test-Path $env:POSHACME_HOME -PathType Container) {
                Set-ConfigRoot $env:POSHACME_HOME
            } else {
                Write-Warning "The POSHACME_HOME environment variable exists but the path it points to, $($env:POSHACME_HOME), does not. Using default config location."
            }
        }

        # create the config folder if it doesn't already exist.
        if (-not (Test-Path (Get-ConfigRoot) -PathType Container)) {
            New-Item -ItemType Directory -Path (Get-ConfigRoot) -Force -EA Stop | Out-Null
        }
    }

    # start at the server level if nothing was specified or specifically requested
    if (!$Level -or $Level -eq 'Server') {

        # load the current ACME directory into memory if it exists on disk
        $dirUrl = [string](Get-Content (Join-Path (Get-ConfigRoot) 'current-server.txt') -EA Ignore)
        if (![string]::IsNullOrWhiteSpace($dirUrl)) {

            Set-DirFolder (ConvertTo-DirFolder $dirUrl)
            $script:Dir = Get-PAServer $dirUrl

            # deal with cert validation options between PS editions
            Set-CertValidation $script:Dir.SkipCertificateCheck

            $ImportAccount = $true

        } else {
            # wipe references since we have no current server
            $script:DirFolder = $null
            $script:Dir = $null
            $script:AcctFolder = $null
            $script:Acct = $null
            $script:Order = $null
        }
    }

    if ($ImportAccount -or $Level -eq 'Account') {

        # load the current account into memory if it exists on disk
        $acctID = [string](Get-Content (Join-Path (Get-DirFolder) 'current-account.txt') -EA Ignore)
        if (![string]::IsNullOrWhiteSpace($acctID)) {

            $script:AcctFolder = Join-Path (Get-DirFolder) $acctID
            $script:Acct = Get-PAAccount $acctID

            $ImportOrder = $true

            # Check for a v3 plugindata.xml file and convert it to order-specific v4
            # files.
            $pDataV3File = Join-Path $script:AcctFolder 'plugindata.xml'
            if (Test-Path $pDataV3File -PathType Leaf) {
                Write-Debug "Migrating v3 plugindata.xml"
                $pDataV3 = Import-Clixml $pDataV3File

                # Loop through the available orders
                Get-PAOrder -List -Refresh | ForEach-Object {
                    if ($_.Plugin) {
                        Write-Debug "Migrating for $($_.MainDomain)"
                        Export-PluginArgs $_.MainDomain $_.Plugin $pDataV3
                    } else {
                        Write-Debug "No Plugins defined for order $($_.MainDomain)"
                    }
                }

                Move-Item $pDataV3File (Join-Path $script:AcctFolder 'plugindata.xml.v3') -Force
            }

        } else {
            # wipe references since we have no current account
            $script:AcctFolder = $null
            $script:Acct = $null
            $script:Order = $null
        }
    }

    if ($ImportOrder -or $Level -eq 'Order') {

        # load the current order into memory if it exists on disk
        $domain = [string](Get-Content (Join-Path $script:AcctFolder 'current-order.txt') -EA Ignore)
        if (![string]::IsNullOrWhiteSpace($domain)) {

            $script:Order = Get-PAOrder $domain

        } else {
            # wipe references since we have no current order
            $script:Order = $null
        }
    }

}
