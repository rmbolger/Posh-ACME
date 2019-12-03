function Repair-ISODate {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Position=0)]
        $InputDate
    )

    # PowerShell Core's JSON serializer tries to helpfully convert ISO 8601 dates
    # to a DateTime object. This is a breaking change from PowerShell 5.1 which just
    # leaves them as normal strings. In order to retain compatibility between editions,
    # we need to un-parse the DateTime objects back to ISO 8601 strings so that the code
    # that assumes they're strings doesn't break.

    # Basically any input that's *not* a DateTime, we're going to return as-is. Otherwise,
    # we're sending back the ISO 8601 string for the specified DateTime object.
    if ($InputDate -and $InputDate -is [DateTime]) {

        return $InputDate.ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)

    } else { return $InputDate }
}
