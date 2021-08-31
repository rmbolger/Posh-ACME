[CmdletBinding()]
param()

# Because Mkdocs generates some HTML with inline scripts and styles
# that may change over time, we need an easy way to update our
# CSP header with their SHA256 hashes that is better than changing
# it to Report-Only, enabling browser Dev Tools, and checking the
# console for errors after an update.

$sha256 = [Security.Cryptography.SHA256]::Create()

# grab the raw contents of all generated HTML files
$html = Get-ChildItem *.html -Recurse | Get-Content -Raw

# create regex as necessary
$reScript = [regex]'<script>(?<src>.*)</script>'

# find all script instances
$reScript.Matches($html) | ForEach-Object {
    # pull out the matched script source
    $_.Groups['src'].Value
}  | Group-Object | ForEach-Object {

    $content = $_.Name

    $tagBytes = [Text.Encoding]::UTF8.GetBytes($content)
    $tagHash = [Convert]::ToBase64String($sha256.ComputeHash($tagBytes))
    [pscustomobject]@{
        cspSection = 'script-src'
        hash = "'sha256-$tagHash'"
        instances = $_.Count
        contents = $content
    }

} | Sort-Object hash
