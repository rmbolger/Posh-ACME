function ConvertTo-DnsPersistDomain {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Domain
    )

    Process {

        # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-03.html#section-12.2
        $name = $Domain.Trim()
        if ($name.EndsWith('.', [StringComparison]::Ordinal)) {
            $name = $name.Substring(0, $name.Length - 1)
        }
        if (-not $name) {
            throw 'Domain is empty after removing whitespace.'
        }
        if ($name.EndsWith('.', [StringComparison]::Ordinal)) {
            throw "Domain '$Domain' has more than one trailing dot."
        }

        # Internationalized names must already be in A-label form. Unicode mapping is not performed.
        if ($name -cmatch '[^\x00-\x7F]') {
            throw "Domain '$Domain' contains non-ASCII characters. Convert internationalized names to their A-label (xn--) form first."
        }

        return $name.ToLowerInvariant()

    }

}
