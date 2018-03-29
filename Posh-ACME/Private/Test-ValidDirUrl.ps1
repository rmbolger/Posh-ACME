function Test-ValidDirUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$DirUrl,
        [switch]$ThrowOnFail
    )

    # anything that begins with https:// is hypothetically ok
    # we're not going to actually query the directory here
    if ($DirUrl -like 'https://*') {
        return $true
    }

    # anything else must exist in our WellKnownDirs object
    if ($script:WellKnownDirs.ContainsKey($DirUrl)) {
        return $true
    }

    # otherwise, fail
    if ($ThrowOnFail) {
        throw "$_ is invalid. Must be $($script:WellKnownDirs.Keys -join ',') or a full https:// URL."
    } else {
        return $false
    }
}
