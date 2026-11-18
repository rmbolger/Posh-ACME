Describe "Invoke-Wedos" {

    BeforeAll {
        . (Join-Path $PSScriptRoot '..\Posh-ACME\Plugins\WEDOS.ps1')
        $script:UseBasic = @{UseBasicParsing = $true}
        Mock Invoke-RestMethod { [pscustomobject]@{ response = [pscustomobject]@{ code = 1000 } } }
    }

    It "Doesn't write the password hash to the debug stream" {
        # sha1(password) is all an attacker needs to build the auth value for any hour
        $cred = [pscredential]::new('user@example.com', (ConvertTo-SecureString 'Hunter2Sentinel' -AsPlainText -Force))
        $hashBytes = [Security.Cryptography.SHA1]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes('Hunter2Sentinel'))
        $pHash = [BitConverter]::ToString($hashBytes).Replace('-','').ToLower()

        $DebugPreference = 'Continue'
        $log = Invoke-Wedos 'ping' $cred 5>&1 | Out-String
        $log | Should -Not -Match $pHash
    }
}
