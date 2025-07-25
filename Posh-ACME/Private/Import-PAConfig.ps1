function Import-PAConfig {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateSet('Server','Account','Order')]
        [string]$Level,
        [switch]$NoRefresh
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
        # based on the POSHACME_HOME environment variable
        if (-not [string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
            # expand any embedded environment variables
            $customHome = [Environment]::ExpandEnvironmentVariables($env:POSHACME_HOME)
            if (Test-Path $customHome -PathType Container) {
                Set-ConfigRoot $customHome
            } else {
                Write-Warning "The POSHACME_HOME environment variable exists but the path it points to, $($customHome), does not. Using default config location."
            }
        }

        # create the config folder if it doesn't already exist.
        if (-not (Test-Path (Get-ConfigRoot) -PathType Container)) {
            New-Item -ItemType Directory -Path (Get-ConfigRoot) -Force -EA Stop | Out-Null
        }
    }

    # start at the server level if nothing was specified or specifically requested
    if (-not $Level -or $Level -eq 'Server') {

        # load and refresh the current ACME directory into memory if it exists on disk
        $dirUrl = [string](Get-Content (Join-Path (Get-ConfigRoot) 'current-server.txt') -EA Ignore)
        if (![string]::IsNullOrWhiteSpace($dirUrl)) {

            if ($NoRefresh) {
                $script:Dir = Get-PAServer -DirectoryUrl $dirUrl
            } else {
                $script:Dir = Get-PAServer -DirectoryUrl $dirUrl -Refresh
            }

            # deal with cert validation options between PS editions
            Set-CertValidation $script:Dir.SkipCertificateCheck

            $ImportAccount = $true

        } else {
            # wipe references since we have no current server
            $script:Dir = $null
            $script:Acct = $null
            $script:Order = $null
        }
    }

    if ($ImportAccount -or $Level -eq 'Account') {

        # load the current account into memory if it exists on disk
        $acctID = [string](Get-Content (Join-Path $script:Dir.Folder 'current-account.txt') -EA Ignore)
        if (![string]::IsNullOrWhiteSpace($acctID)) {

            $script:Acct = Get-PAAccount -ID $acctID

            if ($script:Acct) {
                $ImportOrder = $true
            } else {
                Write-Warning "Unable to locate current account $acctID"
                $script:Order = $null
            }
        } else {
            # wipe references since we have no current account
            $script:Acct = $null
            $script:Order = $null
        }

        if ($script:Acct) {
            # Check for a v3 plugindata.xml file and convert it to order-specific v4
            # files.
            $pDataV3File = Join-Path $script:Acct.Folder 'plugindata.xml'
            if (Test-Path $pDataV3File -PathType Leaf) {
                Write-Debug "Migrating v3 plugindata.xml"
                $pDataV3 = Import-Clixml $pDataV3File

                # Loop through the available orders
                Get-PAOrder -List -Refresh | ForEach-Object {
                    if ($_.Plugin) {
                        Write-Debug "Migrating for order '$($_.Name)'"
                        Export-PluginArgs -Order $_ -PluginArgs $pDataV3
                    } else {
                        Write-Debug "No Plugins defined for order '$($_.Name)'"
                    }
                }

                Move-Item $pDataV3File (Join-Path $script:Acct.Folder 'plugindata.xml.v3') -Force
            }
        }
    }

    if ($ImportOrder -or $Level -eq 'Order') {

        # load the current order into memory if it exists on disk
        $orderName = [string](Get-Content (Join-Path $script:Acct.Folder 'current-order.txt') -EA Ignore)
        if (-not [string]::IsNullOrWhiteSpace($orderName)) {

            # replace wildcard characters to filesystem friendly ! characters
            # for 4.5 and earlier compatibility
            $orderName = $orderName.Replace('*','!')

            $script:Order = Get-PAOrder -Name $orderName

        } else {
            # wipe references since we have no current order
            $script:Order = $null
        }
    }

}
