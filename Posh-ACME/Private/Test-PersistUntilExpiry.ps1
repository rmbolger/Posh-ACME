function Test-PersistUntilExpiry {
    [CmdletBinding()]
    param(
        # the authorization identifier as returned by the ACME server, possibly with a wildcard prefix
        [Parameter(Mandatory)]
        [string]$Identifier,

        [Parameter(Mandatory)]
        [string]$IssuerDomainName
    )

    # match the identifier form that Publish-DnsPersistChallenge stores in the cache
    $idRaw = if ($Identifier.StartsWith('*.', [StringComparison]::Ordinal)) { $Identifier.Substring(2) } else { $Identifier }
    $idConverted = if (Test-IPShaped $idRaw) { $idRaw.ToLowerInvariant() } else { ConvertTo-DnsPersistDomain $idRaw }

    # Lossy match. The cache entry's account hash isn't compared because it depends on whether
    # -NoDomainCorrelationMitigation was used. No DNS queries are made.
    $expiryCutoff = [DateTimeOffset]::UtcNow.AddHours(1)
    $expiring = @(Get-PublishedPersistChallenge) | Where-Object {
        $_.Domain -eq $idConverted -and
        $_.IssuerDomainName -eq $IssuerDomainName -and
        $_.PersistUntil -and $_.PersistUntil -le $expiryCutoff
    }
    if ($expiring) {
        Write-Warning "The cached dns-persist-01 record for $idConverted has a persistUntil of $($expiring[0].PersistUntil.ToString('o')), which has expired or expires within 1 hour."
    }
}
