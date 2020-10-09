# The functions in this file exist solely to allow
# easier mocking in Pester tests.

# this one
function TestData {
    # This one is specifically for mocking so we can more easily
    # pass data to the module scope from where it might be defined
    # in the test-wide BeforeAll section.
}

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
