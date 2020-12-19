function Get-AlternateLinks {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]$Headers    # gotta be generic since editions have different types
    )

    # Desktop Header: System.Collections.Generic.Dictionary<string,string>
    # Core Header   : System.Collections.Generic.Dictionary<string,IEnumerable<string>>

    $reAltLink = '<(?<uri>\S+)>;rel="alternate"'

    if ($Headers -and $Headers.ContainsKey('Link')) {
        # Regardless of how the link headers are formatted in the response, Desktop
        # edition will concatenate multiple values with a comma. But Core edition
        # will return each one in a string array. So we're going to split each string
        # on a comma to normalize the output.
        $links = $response.Headers['Link'] | ForEach-Object {
            $_.Split(',') | ForEach-Object { $_ }
        }
        Write-Debug "links has $($links.Count) entries"

        # now find and return the URIs for only the rel="alternate" ones
        $links | ForEach-Object {
            if ($_ -match $reAltLink) {
                $matches['uri']
            }
        }
    }

}
