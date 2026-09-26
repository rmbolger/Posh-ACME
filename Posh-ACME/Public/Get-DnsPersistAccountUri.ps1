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
    }

    Process {
        trap { $PSCmdlet.ThrowTerminatingError($_) }

        # Normalize the domain name according to draft suggestions
        # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-02.html#section-9.2
        $origDomain = $Domain
        $Domain = $Domain.Trim().ToLowerInvariant().Normalize([Text.NormalizationForm]::FormC)
        # Remove any common ACME DNS persist prefixes from the domain name.
        do {
            $checkNext = $false
            foreach ($prefix in @('_validation-persist.','*.')) {
                if ($Domain.StartsWith($prefix, [StringComparison]::Ordinal)) {
                    $Domain = $Domain.Substring($prefix.Length)
                    $checkNext = $true
                    break
                }
            }
        } while ($checkNext)

        # double check the domain isn't empty after removing prefixes
        if (-not $Domain) {
            throw 'Domain is empty after removing whitespace and dns-persist prefixes.'
        }

        # convert the domain to its ASCII-compatible encoding (A-label) form
        $idn = [Globalization.IdnMapping]::new()
        $Domain = $idn.GetAscii($Domain).ToLowerInvariant()
        # remove any trailing dot from the domain name
        if ($Domain.EndsWith('.')) {
            $Domain = $Domain.Substring(0, $Domain.Length - 1)
        }
        Write-Debug "Domain '$origDomain' normalized to '$Domain'"

        # validate the resulting domain is still valid
        if (-not $Domain -or $Domain.EndsWith('.')) {
            throw 'Domain must contain at least one label and no more than one trailing dot.'
        }
        if ($Domain.Length -gt 253) {
            throw 'Domain exceeds the maximum length of 253 octets.'
        }
        foreach ($label in $Domain.Split('.')) {
            if ($label.Length -gt 63 -or $label -cnotmatch '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$') {
                throw "Domain contains an invalid DNS label: $label"
            }
        }

        # Build the octet sequence: length_of_domain || domain_name || key || account_URL
        $hashInputBytes = [Collections.Generic.List[byte]]::new()
        $hashInputBytes.Add([byte]$Domain.Length)
        $hashInputBytes.AddRange([Text.Encoding]::ASCII.GetBytes($Domain))
        $hashInputBytes.AddRange([Text.Encoding]::ASCII.GetBytes($thumb))
        $hashInputBytes.AddRange([Text.Encoding]::ASCII.GetBytes($accountLocation))
        $hashInputBytes = $hashInputBytes.ToArray()
        Write-Debug "Hashing combined value: $([Text.Encoding]::ASCII.GetString($hashInputBytes))"
        $hashB64 = ConvertTo-Base64Url $sha256.ComputeHash($hashInputBytes)
        $accountUri = '{0}{1}/{2}' -f $AccountHashPrefix, $HashAlgorithm, $hashB64

        return $accountUri
    }
}
