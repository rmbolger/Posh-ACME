#Requires -Modules platyPS

[CmdletBinding()]
param()

# Update our Markdown function files
$files = Update-MarkdownHelp .\docs\Functions\

# Un-capitalize the section names and add 'powershell' tag to syntax code blocks
$files | ForEach-Object {
    $inSyntax = $false
    $inCodeBlock = $false

    $markdown = $_ | Get-Content | ForEach-Object {

        if     ($_ -eq '## SYNOPSIS')      { '## Synopsis' }
        elseif ($_ -eq '## SYNTAX')        { '## Syntax';      $inSyntax = $true  }
        elseif ($_ -eq '## DESCRIPTION')   { '## Description'; $inSyntax = $false }
        elseif ($_ -eq '## EXAMPLES')      { '## Examples' }
        elseif ($_ -eq '## PARAMETERS')    { '## Parameters' }
        elseif ($_ -eq '## INPUTS')        { '## Inputs' }
        elseif ($_ -eq '## OUTPUTS')       { '## Outputs' }
        elseif ($_ -eq '## NOTES')         { '## Notes' }
        elseif ($_ -eq '## RELATED LINKS') { '## Related Links' }
        elseif ($inSyntax -and -not $inCodeBlock -and $_ -eq '```') {
            $inCodeBlock = $true
            '```powershell'
        }
        elseif ($inSyntax -and $inCodeBlock -and $_ -eq '```') {
            $inCodeBlock = $false
            $_
        }
        else { $_ }
    }
    $markdown | Out-File $_.FullName -Encoding utf8 -Force
}

# Remove empty sections
$files | ForEach-Object {
    $raw = $_ | Get-Content -Raw
    $markdown = ($raw -replace '## Inputs\r\n\r\n## ','## ' -replace '## Outputs\r\n\r\n## ','## ' -replace '## Notes\r\n\r\n## ','## ').Trim()
    $markdown | Out-File $_.FullName -Encoding utf8 -Force
}
