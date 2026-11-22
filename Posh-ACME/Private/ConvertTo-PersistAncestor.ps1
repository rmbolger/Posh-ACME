function ConvertTo-PersistAncestor {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [string]$Ancestor
    )

    Process {

        if ($Ancestor.Trim().StartsWith('*.', [StringComparison]::Ordinal)) {
            throw "PersistAncestor '$Ancestor' must not include a wildcard prefix."
        }
        if (Test-IPShaped $Ancestor.Trim()) {
            throw "PersistAncestor '$Ancestor' must be a domain name, not an IP address."
        }

        $name = ConvertTo-DnsPersistDomain $Ancestor

        # require at least two labels so a bare TLD can't be used by accident
        $labels = $name.Split('.')
        $validLabels = @($labels | Where-Object { $_ -match '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$' })
        if ($labels.Count -lt 2 -or $validLabels.Count -ne $labels.Count) {
            throw "PersistAncestor '$Ancestor' is not a valid domain name."
        }

        # the complete _validation-persist.<ancestor> name must fit in the DNS length limit
        if (('_validation-persist.' + $name).Length -gt 253) {
            throw "PersistAncestor '$Ancestor' is too long to form a valid _validation-persist name."
        }

        $name
    }
}
