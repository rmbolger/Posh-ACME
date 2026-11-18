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

        # IP identifiers are represented by their normalized reverse zone name.
        # https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-03.html#section-7.1
        if (Test-IPShaped $name) {
            $ip = $null
            if (-not [Net.IPAddress]::TryParse($name, [ref]$ip) -or $name.Contains('%')) {
                throw "IP address '$Domain' is not valid."
            }
            $bytes = $ip.GetAddressBytes()
            if ($ip.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
                # reject forms like leading zeros that don't round-trip to the canonical address
                if ($ip.ToString() -ne $name) {
                    throw "IPv4 address '$Domain' must use decimal octets without leading zeros."
                }
                return (($bytes[3..0]) -join '.') + '.in-addr.arpa'
            }
            $nibbles = (($bytes | ForEach-Object { $_.ToString('x2') }) -join '').ToCharArray()
            return (($nibbles[31..0]) -join '.') + '.ip6.arpa'
        }

        return $name.ToLowerInvariant()

    }

}
