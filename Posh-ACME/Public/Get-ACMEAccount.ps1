function Get-ACMEAccount {
    [CmdletBinding()]
    param(
        [string[]]$Contact,
        [switch]$AcceptTOS,
        [ValidateScript({Test-ValidKeyLength $_})]
        [string]$AccountKeyLength='2048'
    )


    # no args
      # use existing account if it exists
      # or create new default account

}