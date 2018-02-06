Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "ConvertFrom-Base64Url" {

    InModuleScope Posh-ACME {
        It "decodes (empty)"  { ConvertFrom-Base64Url ''       | Should -Be '' }
        It "decodes 'f'"      { ConvertFrom-Base64Url 'Zg'      | Should -Be 'f' }
        It "decodes 'fo'"     { ConvertFrom-Base64Url 'Zm8'     | Should -Be 'fo' }
        It "decodes 'foo'"    { ConvertFrom-Base64Url 'Zm9v'    | Should -Be 'foo' }
        It "decodes 'foob'"   { ConvertFrom-Base64Url 'Zm9vYg'   | Should -Be 'foob' }
        It "decodes 'fooba'"  { ConvertFrom-Base64Url 'Zm9vYmE'  | Should -Be 'fooba' }
        It "decodes 'foobar'" { ConvertFrom-Base64Url 'Zm9vYmFy' | Should -Be 'foobar' }
        It "decodes '????'"   { ConvertFrom-Base64Url 'Pz8_Pw'   | Should -Be '????' }
        It "decodes '>>>>'"   { ConvertFrom-Base64Url 'Pj4-Pg'   | Should -Be '>>>>' }
        It "decodes strings from pipeline" {
            'YXNkZg','cXdlcg' | ConvertFrom-Base64Url | Should -Be 'asdf','qwer'
        }
        It "throws on invalid length" {
            { ConvertFrom-Base64Url '12345' } | Should -Throw
        }

        It "returns byte[] with -AsByteArray" {
            ConvertFrom-Base64Url 'Zm9vYmFy' -AsByteArray | Should -Be ([byte[]](102,111,111,98,97,114))
        }

        # Since we're using the native [Convert]::FromBase64String under the hood, we'll
        # skip testing the various combinations of characters that should throw an error.

    }

}