Import-Module Posh-ACME

Describe "ConvertTo-Base64Url" {

    InModuleScope Posh-ACME {
        It "encodes (empty)"  { ConvertTo-Base64Url ''       | Should -Be '' }
        It "encodes 'f'"      { ConvertTo-Base64Url 'f'      | Should -Be 'Zg' }
        It "encodes 'fo'"     { ConvertTo-Base64Url 'fo'     | Should -Be 'Zm8' }
        It "encodes 'foo'"    { ConvertTo-Base64Url 'foo'    | Should -Be 'Zm9v' }
        It "encodes 'foob'"   { ConvertTo-Base64Url 'foob'   | Should -Be 'Zm9vYg' }
        It "encodes 'fooba'"  { ConvertTo-Base64Url 'fooba'  | Should -Be 'Zm9vYmE' }
        It "encodes 'foobar'" { ConvertTo-Base64Url 'foobar' | Should -Be 'Zm9vYmFy' }
        It "encodes '????'"   { ConvertTo-Base64Url '????'   | Should -Be 'Pz8_Pw' }
        It "encodes '>>>>'"   { ConvertTo-Base64Url '>>>>'   | Should -Be 'Pj4-Pg' }
        It "encodes '>>>>' bytes" {
            ConvertTo-Base64Url ([byte[]]@(62,62,62,62)) | Should -Be 'Pj4-Pg'
        }
        It "encodes empty array" {
            ConvertTo-Base64Url @() | Should -Be ''
        }
        It "encodes strings from pipeline" {
            'asdf','qwer' | ConvertTo-Base64Url | Should -Be 'YXNkZg','cXdlcg'
        }
    }

}