function Get-IssuerFromChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [PSObject]$Challenge
    )

    if (-not $Challenge) {
        Write-Debug "Unable to get issuer from challenge because challenge is null."
        return
    }
    if ('issuerDomainNames' -notin $Challenge.PSObject.Properties.Name) {
        Write-Verbose "dns-persist-01 challenge for $($Challenge.url) has no issuerDomainNames field."
        return
    }

    $issuers = $Challenge.issuerDomainNames

    # Sanity check issuerDomainNames.
    # "Clients MUST consider a challenge malformed if the issuerDomainNames array is empty
    # or if it contains more than 10 entries, and MUST reject such challenges. Each domain
    # name MUST NOT exceed 253 octets in length."
    # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-02.html#section-3.1
    if (-not $issuers -or $issuers.Length -eq 0) {
        Write-Verbose "dns-persist-01 challenge $($Challenge.url) has no issuer domain names."
        return
    }
    if ($issuers.Length -gt 10) {
        Write-Verbose "dns-persist-01 challenge for $($Challenge.url) has more than 10 issuer domain names. Clients must reject this."
        return
    }
    # Ensure each domain name is ASCII and does not exceed 253 octets in length.
    foreach ($issuer in $issuers) {
        $octetLength = [Text.Encoding]::ASCII.GetByteCount($issuer)
        if ($issuer -cmatch '[^\x00-\x7F]' -or $octetLength -gt 253) {
            Write-Verbose "dns-persist-01 challenge for $($Challenge.url) has an issuer domain name that is not ASCII or exceeding 253 octets. Clients must reject this."
            return
        }
    }

    # "The order of names in the array has no significance."
    # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-02.html#section-7.6
    # So sort them to make it more likely that we get the same value for each challenge on each run.
    $issuers = @($issuers | Sort-Object)

    return $issuers[0]
}
