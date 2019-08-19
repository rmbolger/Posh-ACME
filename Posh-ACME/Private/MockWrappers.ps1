# The functions in this file exist solely to allow
# easier mocking in Pester tests.

function Get-DateTimeOffsetNow {
    [System.DateTimeOffset]::Now
}

function Get-ConfigRoot {
    $script:ConfigRoot
}

function Set-ConfigRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Path
    )
    $script:ConfigRoot = $Path
}

function Get-DirFolder {
    $script:DirFolder
}

function Set-DirFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Path
    )
    $script:DirFolder = $Path
}
