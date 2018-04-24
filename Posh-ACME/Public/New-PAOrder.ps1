function New-PAOrder {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('PoshACME.PAOrder')]
    param(
        [Parameter(Mandatory,Position=0)]
        [string[]]$Domain,
        [Parameter(Position=1)]
        [ValidateScript({Test-ValidKeyLength $_ -ThrowOnFail})]
        [string]$KeyLength='2048',
        [switch]$OCSPMustStaple,
        [switch]$Force
    )

    # Make sure we have an account configured
    if (!($acct = Get-PAAccount)) {
        throw "No ACME account configured. Run Set-PAAccount first."
    }

    # null the local instance of $order so it's not confused with the script-scoped version
    $order = $null

    # separate the SANs
    $SANs = @($Domain | Where-Object { $_ -ne $Domain[0] }) | Sort-Object

    # There's a chance we may be overwriting an existing order here. So check for
    # confirmation if certain conditions are true
    if (!$Force) {
        try { $order = Get-PAOrder $Domain[0] -Refresh } catch {}

        # skip confirmation if the SANs or KeyLength are different
        # regardless of the original order status
        # or if the order is pending but expired
        if ( ($order -and ($KeyLength -ne $order.KeyLength -or
             ($SANs -join ',') -ne (($order.SANs | Sort-Object) -join ',') -or
             ($order.status -eq 'pending' -and (Get-Date) -gt (Get-Date $order.expires)) ))) {
            # do nothing

        # confirm if previous order is still in progress
        } elseif ($order -and $order.status -in 'pending','ready','processing') {

            if (!$PSCmdlet.ShouldContinue("Do you wish to overwrite?",
                "Existing order with status $($order.status).")) { return }

        # confirm if previous order not up for renewal
        } elseif ($order -and $order.status -eq 'valid' -and (Get-Date) -lt (Get-Date $order.RenewAfter)) {

            if (!$PSCmdlet.ShouldContinue("Do you wish to overwrite?",
                "Existing order has not reached suggested renewal window.")) { return }
        }
    }

    Write-Debug "Creating new $KeyLength order with domains: $($Domain -join ', ')"

    # hydrate the key
    $acctKey = $acct.key | ConvertFrom-Jwk

    # build the protected header for the request
    $header = @{
        alg   = $acct.alg;
        kid   = $acct.location;
        nonce = $script:Dir.nonce;
        url   = $script:Dir.newOrder;
    }

    # build the payload object
    $payload = @{identifiers=@()}
    foreach ($d in $Domain) {
        $payload.identifiers += @{type='dns';value=$d}
    }
    $payloadJson = $payload | ConvertTo-Json -Compress

    # send the request
    try {
        $response = Invoke-ACME $header.url $acctKey $header $payloadJson -EA Stop
    } catch { throw }
    Write-Debug "Response: $($response.Content)"

    # process the response
    $order = $response.Content | ConvertFrom-Json
    $order.PSObject.TypeNames.Insert(0,'PoshACME.PAOrder')
    $order | Add-Member -MemberType NoteProperty -Name 'MainDomain' -Value $Domain[0]
    $order | Add-Member -MemberType NoteProperty -Name 'SANs' -Value $SANs
    $order | Add-Member -MemberType NoteProperty -Name 'KeyLength' -Value $KeyLength
    $order | Add-Member -MemberType NoteProperty -Name 'RenewAfter' -Value $null
    $order | Add-Member -MemberType NoteProperty -Name 'MustStaple' -Value $OCSPMustStaple.IsPresent
    $order | Add-Member -MemberType NoteProperty -Name 'DnsPlugin' -Value $null
    $order | Add-Member -MemberType NoteProperty -Name 'DnsSleep' -Value $null
    $order | Add-Member -MemberType NoteProperty -Name 'ValidationTimeout' -Value $null

    # make sure there's a certificate field for later
    if ('certificate' -notin $order.PSObject.Properties.Name) {
        $order | Add-Member -MemberType NoteProperty -Name 'certificate' -Value $null
    }

    # add the location from the header
    if ($response.Headers.ContainsKey('Location')) {
        Write-Debug "Adding location $($response.Headers['Location'])"
        $order | Add-Member -MemberType NoteProperty -Name 'location' -Value $response.Headers['Location']
    } else {
        throw 'No Location header found in newOrder output'
    }

    # save it to memory and disk
    $order.MainDomain | Out-File (Join-Path $script:AcctFolder 'current-order.txt') -Force
    $script:Order = $order
    $script:OrderFolder = Join-Path $script:AcctFolder $order.MainDomain.Replace('*','!')
    if (!(Test-Path $script:OrderFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $script:OrderFolder -Force | Out-Null
    }
    $order | ConvertTo-Json | Out-File (Join-Path $script:OrderFolder 'order.json') -Force

    # backup any old certs/requests that might exist
    $oldFiles = Get-ChildItem (Join-Path $script:OrderFolder *) -Include *.csr,*.cer,*.pfx
    $oldFiles | Move-Item -Destination { "$($_.FullName).bak" } -Force
    # keep a copy of the private key in case we need to re-use
    $oldKey = Get-ChildItem (Join-Path $script:OrderFolder *) -Include *.key
    $oldKey | Copy-Item -Destination { "$($_.FullName).bak" } -Force
    return $order




    <#
    .SYNOPSIS
        Create a new order on the current ACME account.

    .DESCRIPTION
        Creating an ACME order is the first step of the certificate request process. To create a SAN certificate with multiple names, include them all in an array for the -Domain parameter. The first name in the list will be considered the "MainDomain" and will also be in the certificate subject field. LetsEncrypt currently limits SAN certificates to 100 names.

        Be aware that only one order per MainDomain can exist with this module. Subsequent orders that have the same MainDomain will overwrite previous orders and certificates under the assumption that you are trying to renew or update the certificate with additional names.

    .PARAMETER Domain
        One or more domain names to include in this order/certificate. The first one in the list will be considered the "MainDomain" and be set as the subject of the finalized certificate.

    .PARAMETER KeyLength
        The type and size of private key to use. For RSA keys, specify a number between 2048-4096 (divisible by 128). For ECC keys, specify either 'ec-256' or 'ec-384'. Defaults to '2048'.

    .PARAMETER OCSPMustStaple
        If specified, the certificate generated for this order will have the OCSP Must-Staple flag set.

    .PARAMETER Force
        If specified, confirmation prompts that may have been generated will be skipped.

    .EXAMPLE
        New-PAOrder site1.example.com

        Create a new order for the specified domain using the default key length.

    .EXAMPLE
        New-PAOrder -Domain 'site1.example.com','site2.example.com','site3.example.com'

        Create a new SAN order for the specified domains using the default key length.

    .EXAMPLE
        New-PAOrder site1.example.com 4096

        Create a new order for the specified domain using an RSA 4096 bit key.

    .EXAMPLE
        New-PAOrder 'site1.example.com','site2.example.com' ec-384 -Force

        Create a new SAN order for the specified domains using an ECC key using P-384 curve that ignores any confirmations.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        Set-PAOrder

    #>
}
