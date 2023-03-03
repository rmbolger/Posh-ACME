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

        # https://datatracker.ietf.org/doc/draft-todo-chariton-dns-account-01/
        # https://www.ietf.org/archive/id/draft-todo-chariton-dns-account-01-02.html

        # *  Construct the validation domain name by prepending the following
        #    label to the domain name being validated:
        #
        # "_acme-challenge_" || base32(SHA-256(Account Resource URL)[0:10])
        #
        # -  SHA-256 is the SHA hashing operation defined in [RFC6234]
        # -  [0:10] is the operation that selects the first ten bytes (bytes
        #    0 through 9 inclusive) from the previous SHA256 operation
        # -  base32 is the operation defined in [RFC4648]
        # -  Account Resource URL is defined in [RFC8555]
        # -  The ""||"" operator indicates concatenation of strings

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

        "_acme-challenge_$b32Val"
    }
}
