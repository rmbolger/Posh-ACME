function Set-PAAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [string]$id
    )

    # make sure we have a server configured
    if (!(Get-PAServer)) {
        throw "No ACME server configured. Run Set-PAServer first."
    }

    # check for the account folder
    $acctFolder = Join-Path $script:CurrentDirFolder $id
    if (!(Test-Path $acctFolder -PathType Container)) {
        throw "No account folder found with id $id."
    }

    # try to load the acct.json file
    $acct = Get-Content (Join-Path $acctFolder 'acct.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $acct.PSObject.TypeNames.Insert(0,'PoshACME.PAAccount')

    # save it to memory
    $script:CurrentAccount = $acct

    return $acct
}
