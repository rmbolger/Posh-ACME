function ConvertTo-AcctDnsLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('location')]
        [string]$AccountUri
    )

    Begin {
        $sha256 = [Security.Cryptography.SHA256]::Create()
        [string[]]$b32Dict = 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','2','3','4','5','6','7'
    }

    Process {

        # https://datatracker.ietf.org/doc/draft-ietf-acme-dns-account-label/02/

        # Construct the validation domain name by prepending the following two
        # labels to the domain name being validated:
        #
        # "_" || base32(SHA-256(<ACCOUNT_URL>)[0:10]) || "._acme-challenge"

        # - SHA-256 is the SHA hashing operation defined in [RFC6234]
        # - [0:10] is the operation that selects the first ten bytes
        #   (bytes 0 through 9 inclusive) from the previous SHA-256
        #   operation
        # - base32 is the operation defined in [RFC4648]
        # - ACCOUNT_URL is defined in [RFC8555], Section 7.3 as the value
        #   in the Location header field
        # - The || operator indicates concatenation of strings

        # Hash the AccountURI
        try {
            $hashBytes = [byte[]]$sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($AccountUri))
        } catch {
            $PSCmdlet.WriteError($_)
        }

        # Now Base32 encode the first 10 bytes. This is not the most efficient way
        # to do Base32 encoding, but good enough for this very constrained purpose.

        # Write-Verbose ($hashBytes[0..9] -join ' ')

        # convert the first 10 bytes into binary and concatenate
        $hashChunkBinary = -join $hashBytes[0..9].ForEach{
            [Convert]::ToString($_, 2).PadLeft(8, '0')
        }

        # Write-Verbose $hashChunkBinary

        # replace each 5-bit group with it's Base32 dictionary character
        $b32Val = [regex]::Replace($hashChunkBinary, '.{5}', {
            param($Match)
            $b32Dict[[Convert]::ToInt32($Match.Value, 2)]
        })

        '_{0}._acme-challenge' -f $b32Val
    }

    End {
        $sha256.Dispose()
    }
}
