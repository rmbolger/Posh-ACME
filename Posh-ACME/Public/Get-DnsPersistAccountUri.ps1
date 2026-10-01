function Get-DnsPersistAccountUri {
    [CmdletBinding(DefaultParameterSetName='NativeAccount')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string]$Domain,
        [Parameter(Position=1,ParameterSetName='NativeAccount')]
        [PSTypeName('PoshACME.PAAccount')]$Account,
        [Parameter(Mandatory,Position=1,ParameterSetName='ExplicitAccountDetails')]
        [string]$AccountUri,
        [Parameter(Mandatory,Position=2,ParameterSetName='ExplicitAccountDetails')]
        [string]$KeyThumbprint,
        [string]$AccountHashPrefix,
        [ValidateSet('sha-256')]
        [string]$HashAlgorithm='sha-256'
    )

    # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-02.html#section-4.1

    Begin {
        trap { $PSCmdlet.ThrowTerminatingError($_) }

        # prep the SHA-256 hasher for later use
        $sha256 = [Security.Cryptography.SHA256]::Create()

        if ('NativeAccount' -eq $PSCmdlet.ParameterSetName) {
            # make sure any account passed in is actually associated with the current server
            # or if no account was specified, that there's a current account.
            if (-not $Account) {
                if (-not ($Account = Get-PAAccount)) {
                    throw "No Account parameter specified and no current account selected. Try running Set-PAAccount first."
                }
            } elseif ($Account.id -notin (Get-PAAccount -List).id) {
                throw "Specified account id $($Account.id) was not found in the current server's account list."
            }
            # make sure it's valid
            if ($Account.status -ne 'valid') {
                throw "Account status is $($Account.status)."
            }

            # Use the account thumbprint and location values
            $thumb = $Account.thumbprint
            $accountLocation = $Account.location
        }
        else {
            # use the provided account uri and key thumbprint
            $thumb = $KeyThumbprint
            $accountLocation = $AccountUri
        }

        # If AccountHashPrefix wasn't provided, grab it from the ACME server's directory object
        if (-not $AccountHashPrefix) {
            if (-not ($server = Get-PAServer)) {
                throw "AccountHashPrefix not provided and no ACME server configured. Run Set-PAServer first or provide the AccountHashPrefix parameter."
            }
            if (-not ($server.meta.accountHashPrefix)) {
                throw "AccountHashPrefix not provided and the ACME server has not published one. Unable to continue without AccountHashPrefix."
            }
            $AccountHashPrefix = $server.meta.accountHashPrefix
        }

        # Prepare the IDN mapping object for later use in domain normalization
        $idn = [Globalization.IdnMapping]::new()
    }

    Process {
        trap { $PSCmdlet.ThrowTerminatingError($_) }

        # Normalize the domain name according to draft suggestions
        # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-02.html#section-9.2
        $origDomain = $Domain
        $Domain = $Domain.Trim().ToLowerInvariant().Normalize([Text.NormalizationForm]::FormC)

        # Remove accidentally included wildcard prefix and any trailing dots
        if ($Domain.StartsWith('*.', [StringComparison]::Ordinal)) {
            $Domain = $Domain.Substring(2)
        }
        $Domain = $Domain.TrimEnd('.')

        # double check the domain isn't empty now
        if (-not $Domain) {
            throw 'Domain is empty after removing whitespace and wildcard prefixes.'
        }

        # convert the domain to its ASCII-compatible encoding (A-label) form
        $Domain = $idn.GetAscii($Domain).ToLowerInvariant()
        Write-Debug "Domain '$origDomain' normalized to '$Domain'"

        # validate the resulting domain is still valid unless it is using the domain-correlation opt-out ('*')
        if ($Domain -ne '*') {
            if ($Domain.Length -gt 253) {
                throw 'Domain exceeds the maximum length of 253 octets.'
            }
            foreach ($label in $Domain.Split('.')) {
                if ($label.Length -gt 63 -or $label -cnotmatch '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$') {
                    throw "Domain contains an invalid DNS label: $label"
                }
            }
        }

        # Build the octet sequence: length_of_domain || domain_name || key || account_URL
        $hashInputBytes = [Collections.Generic.List[byte]]::new()
        $hashInputBytes.Add([byte]$Domain.Length)
        $hashInputBytes.AddRange([Text.Encoding]::ASCII.GetBytes($Domain))
        $hashInputBytes.AddRange([Text.Encoding]::ASCII.GetBytes($thumb))
        $hashInputBytes.AddRange([Text.Encoding]::ASCII.GetBytes($accountLocation))
        $hashInputBytes = $hashInputBytes.ToArray()
        Write-Debug ("Hash input: length=0x{0:X2}, data={1}" -f
            $hashInputBytes[0],
            [Text.Encoding]::ASCII.GetString($hashInputBytes, 1, $hashInputBytes.Length - 1))
        $hashB64 = ConvertTo-Base64Url $sha256.ComputeHash($hashInputBytes)
        $accountUri = '{0}{1}/{2}' -f $AccountHashPrefix, $HashAlgorithm, $hashB64

        return $accountUri
    }
}
