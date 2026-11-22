function Get-PersistAncestor {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        # the authorization identifier value without any wildcard prefix
        [Parameter(Mandatory,Position=0)]
        [string]$Identifier,

        # validated ancestor domains, as returned by ConvertTo-PersistAncestor
        [Parameter(Mandatory,Position=1)]
        [string[]]$Ancestors
    )

    # only proper whole-label suffixes match. The leading dot enforces the label boundary
    # and excludes the identifier itself. The longest match is the nearest ancestor.
    $id = $Identifier.ToLowerInvariant()
    $Ancestors |
        Where-Object { $id.EndsWith(".$_", [StringComparison]::Ordinal) } |
        Sort-Object -Property Length -Descending |
        Select-Object -First 1
}
