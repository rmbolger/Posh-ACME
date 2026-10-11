function Get-PublishedPersistChallenge {
    [CmdletBinding()]
    param (
    )

    Process {

        $pubCachePath = Join-Path (Get-ConfigRoot) 'PersistedChallenges.json'
        if (-not (Test-Path $pubCachePath)) {
            return
        }

        $pubCache = Get-Content $pubCachePath -Raw | ConvertFrom-Json

        # Output the contents of the cache in a form that could potentially be piped
        # or splatted to Unpublish-DnsPersistChallenge
        $pubCache | Select-Object -Property @{
            Name='Domain'; Expression={$_.fqdn}
        },@{
            Name='HashedAccountUri'; Expression={$_.hashAcctUri}
        },@{
            Name='IssuerDomainName'; Expression={$_.issuer}
        },@{
            Name='AllowWildcard'; Expression={$_.addWildcard}
        },@{
            Name='PersistUntil'; Expression={
                if ($_.persistUntil) {
                    [DateTimeOffset]::FromUnixTimeSeconds($_.persistUntil)
                } else {
                    [Nullable[DateTimeOffset]]$null
                }
            }
        },@{
            Name='FromAccountUri'; Expression={$_.fromAcctUri}
        },@{
            Name='FromAccountThumbprint'; Expression={$_.fromAcctThumb}
        }
    }
}
