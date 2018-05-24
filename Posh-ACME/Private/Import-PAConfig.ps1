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

    # Each leve of the config is dependent on its parent. So if the user changes the server,
    # they need to reload the server and all of the child accounts and orders. But if they only
    # change the account, they only need to reload it and orders. And so on.

    # make sure we have the root config folder
    if ([string]::IsNullOrWhiteSpace($script:ConfigRoot)) {
        if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
            $script:ConfigRoot = Join-Path $env:LOCALAPPDATA 'Posh-ACME'
        } elseif ($IsLinux) {
            $script:ConfigRoot = Join-Path $env:HOME '.config/Posh-ACME'
        } elseif ($IsMacOs) {
            $script:ConfigRoot = Join-Path $env:HOME 'Library/Preferences/Posh-ACME'
        } else {
            throw "Unrecognized PowerShell platform"
        }
        if (!(Test-Path $script:ConfigRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $script:ConfigRoot -Force | Out-Null
        }
    }

    # start at the server level if nothing was specified or specifically requested
    if (!$Level -or $Level -eq 'Server') {

        # load the current ACME directory into memory if it exists on disk
        $dirUrl = [string](Get-Content (Join-Path $script:ConfigRoot 'current-server.txt') -EA SilentlyContinue)
        if (![string]::IsNullOrWhiteSpace($dirUrl)) {

            $dirFolder = $dirUrl.Replace('https://','').Replace(':','_')
            $script:DirFolder = Join-Path $script:ConfigRoot $dirFolder.Substring(0,$dirFolder.IndexOf('/'))
            $script:Dir = Get-PAServer $dirUrl

            # deal with cert validation options between PS editions
            if ($script:Dir.SkipCertificateCheck) {
                Write-Debug "skipping cert validation"
                if ($script:SkipCertSupported) {
                    $script:UseBasic.SkipCertificateCheck = $true
                } else {
                    [CertValidation]::Ignore()
                }
            } else {
                Write-Debug "restoring cert validation"
                if ($script:SkipCertSupported) {
                    $script:UseBasic.SkipCertificateCheck = $false
                } else {
                    [CertValidation]::Restore()
                }
            }

            $ImportAccount = $true
        }
    }

    if ($ImportAccount -or $Level -eq 'Account') {

        # load the current account into memory if it exists on disk
        $acctID = [string](Get-Content (Join-Path $script:DirFolder 'current-account.txt') -EA SilentlyContinue)
        if (![string]::IsNullOrWhiteSpace($acctID)) {

            $script:AcctFolder = Join-Path $script:DirFolder $acctID
            $script:Acct = Get-PAAccount $acctID

            $ImportOrder = $true
        }
    }

    if ($ImportOrder -or $Level -eq 'Order') {

        # load the current order into memory if it exists on disk
        $domain = [string](Get-Content (Join-Path $script:AcctFolder 'current-order.txt') -EA SilentlyContinue)
        if (![string]::IsNullOrWhiteSpace($domain)) {

            $script:OrderFolder = Join-Path $script:AcctFolder $domain.Replace('*','!')
            $script:Order = Get-PAOrder $domain
        }
    }

}
