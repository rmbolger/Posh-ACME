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
    if ('issuer-domain-names' -notin $Challenge.PSObject.Properties.Name) {
        Write-Verbose "dns-persist-01 challenge for $($Challenge.url) has no issuer-domain-names field."
        return
    }

    $issuers = $Challenge.'issuer-domain-names'

    # Sanity check issuer-domain-names.
    # "Clients MUST consider a challenge malformed if the issuer-domain-names array is empty or if it contains
    # more than 10 entries, and MUST reject such challenges."
    # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-01.html#section-3.1
    if (-not $issuers -or $issuers.Length -eq 0) {
        Write-Verbose "dns-persist-01 challenge $($Challenge.url) has no issuer domain names."
        return
    }
    if ($issuers.Length -gt 10) {
        Write-Verbose "dns-persist-01 challenge for $($Challenge.url) has more than 10 issuer domain names. Clients must reject this."
        return
    }

    # "The order of names in the array has no significance."
    # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-01.html#section-7.6
    # So sort them to make it more likely that we get the same value for each challenge on each run.
    $issuers = @($issuers | Sort-Object)

    return $issuers[0]
}
