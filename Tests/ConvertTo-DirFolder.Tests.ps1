Describe "ConvertTo-DirFolder" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    It "Converts Properly" -TestCases @(
        @{ url='https://shorthost/dir'; result='shorthost' }
        @{ url='https://shorthost:8443/dir'; result='shorthost_8443' }
        @{ url='https://acme.example.com/directory'; result='acme.example.com' }
        @{ url='https://acme.example.com:8443/directory'; result='acme.example.com_8443' }
    ) {
        InModuleScope Posh-ACME -Parameters @{Url=$url} {
            param($Url)
            ConvertTo-DirFolder $url
        } | Should -Be (Join-Path 'TestDrive:' $result)
    }
}
