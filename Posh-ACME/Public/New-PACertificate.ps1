function New-PACertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [string[]]$Contact,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$CertKeyLength='2048',
        [switch]$NewCertKey,
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$AccountKeyLength='ec-256',
        [ValidateScript({Test-ValidDirUrl $_ -ThrowOnFail})]
        [Alias('location')]
        [string]$DirectoryUrl='LE_STAGE',
        [ValidateScript({Test-ValidDnsPlugin $_ -ThrowOnFail})]
        [string[]]$DnsPlugin,
        [hashtable]$PluginArgs,
        [switch]$OCSPMustStaple,
        [switch]$Force,
        [int]$DNSSleep=120,
        [int]$ValidationTimeout=60,
        [int]$CertIssueTimeout=60
    )

    # Make sure we have a server set. But don't override the current
    # one unless explicitly specified.
    $dir = Get-PAServer
    if (!$dir -or ('DirectoryUrl' -in $PSBoundParameters.Keys)) {
        Set-PAServer $DirectoryUrl
    } else {
        # refresh the directory info (which should also get a fresh nonce)
        Update-PAServer
    }
    Write-Host "Using directory $($dir.location)"

    # Make sure we have an account set. If Contact and/or AccountKeyLength
    # were specified and don't match the current one but do match a different,
    # one, switch to that. If the specified details don't match any existing
    # accounts, create a new one.
    $acct = Get-PAAccount
    $accts = @(Get-PAAccount -List -Refresh -Status 'valid' @PSBoundParameters)
    if (!$accts -or $accts.Count -eq 0) {
        # no matches for the set of filters, so create new
        Write-Host "Creating a new $AccountKeyLength account with contact: $($Contact -join ', ')"
        $acct = New-PAAccount @PSBoundParameters
    } elseif ($accts.Count -gt 0 -and (!$acct -or $acct.id -notin $accts.id)) {
        # we got matches, but there's no current account or the current one doesn't match
        # so set the first match as current
        $acct = $accts[0]
        Set-PAAccount $acct.id
    }
    Write-Host "Using account $($acct.id)"

    # Check for an existing order from the MainDomain for this call and create a new
    # one if:
    # - -Force was used
    # - it doesn't exist
    # - is invalid
    # - is valid and within the renewal window
    # - is pending, but expired
    # - has different KeyLength
    # - has different SANs
    $order = $null
    try { $order = Get-PAOrder $Domain[0] -Refresh } catch {}
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object
    if ($Force -or !$order -or
        $order.status -eq 'invalid' -or
        ($order.status -eq 'valid' -and (Get-Date) -ge (Get-Date $order.RenewAfter)) -or
        ($order.status -eq 'pending' -and (Get-Date) -gt (Get-Date $order.expires)) -or
        $CertKeyLength -ne $order.KeyLength -or
        ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') ) {

        Write-Host "Creating a new order for $($Domain -join ', ')"
        $order = New-PAOrder $Domain $CertKeyLength -Force
    } else {
        $order | Set-PAOrder
    }
    Write-Host "Using order for $($order.MainDomain) with status $($order.status)"

    # deal with "pending" orders that may have authorization challenges to prove
    if ($order.status -eq 'pending') {
        Submit-ChallengeValidation @PSBoundParameters

        # refresh the order status
        $order = Get-PAOrder -Refresh
    }

    # if we've reached this point, it should mean that we're ready to finalize the
    # order. The order status is supposed to be 'ready', but that ready status is a
    # recent addition to the ACME spec and LetsEncrypt hasn't implemented it yet.
    # So for now, we have to check the status of the order's authorizations to make
    # sure it's ready for finalization.
    $auths = $order | Get-PAAuthorizations
    if ($order.status -eq 'ready' -or
        ($order.status -eq 'pending' -and !($auths | Where-Object { $_.status -ne 'valid' })) ) {

        # make the finalize call
        Write-Host "Finalizing the order."
        Submit-OrderFinalize @PSBoundParameters

        # refresh the order status
        $order = Get-PAOrder -Refresh
    }

    # The order should now be finalized and the status should be valid. The only
    # thing left to do is download the cert and chain and write the results to
    # disk
    if ($order.status -eq 'valid') {
        if ([string]::IsNullOrWhiteSpace($order.certificate)) {
            throw "Order status is valid, but no certificate URL was found."
        }

        # build output paths
        $certFile      = Join-Path $script:OrderFolder 'cert.cer'
        $keyFile       = Join-Path $script:OrderFolder 'cert.key'
        $chainFile     = Join-Path $script:OrderFolder 'chain.cer'
        $fullchainFile = Join-Path $script:OrderFolder 'fullchain.cer'
        $pfxFile       = Join-Path $script:OrderFolder 'cert.pfx'

        # Download the cert chain, split it up, and generate a PFX
        Invoke-WebRequest $order.certificate -OutFile $fullchainFile
        Split-CertChain $fullchainFile $certFile $chainFile
        Export-CertPfx $certFile $keyFile $pfxFile

        Write-Host "Wrote certificate files to $($script:OrderFolder)"
    }

}
