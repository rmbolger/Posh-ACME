# The functions in this file exist solely to allow
# easier mocking in Pester tests.

function Get-DateTimeOffsetNow {
    [System.DateTimeOffset]::Now
}

function Get-DirFolder {
    $script:DirFolder
}
