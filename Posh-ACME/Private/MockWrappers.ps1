# The functions in this file exist solely to allow
# easier mocking in Pester tests.

function Get-DateTimeOffsetNow {
    [System.DateTimeOffset]::Now
}

function Get-ConfigRoot {
    $script:ConfigRoot
}

function Get-DirFolder {
    $script:DirFolder
}
